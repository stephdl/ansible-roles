#!/usr/bin/perl -w
  
use IO::Socket;
use Getopt::Long;
use File::Basename;
use File::Path qw(make_path);
use IO::Handle;

my $maxlen = 16384;
my $port = 514;
my $maxlines = 10000;
my $logdir = '/run/cs-gelf-server/';

GetOptions(
  "port=i" => \$port,
  "maxlines=i" => \$maxlines,
  "logdir=s" => \$logdir
);

if ($port !~ /^\d+$/ or $port < 1 or $port > 65535){
  die "Invalid port $port\n";
}
if ($maxlines !~ /^\d+/ or $maxlines < 10){
  die "Invalid max line specified\n";
}
if (not -d $logdir){
  die "$logdir doesn't exists or is not a directory\n";
}

# Remove trailing / of the logdir, it's not nice in the logs when you have double /
$logdir =~ s/\/$//;

# Create files so crowdsec can open them before any lines are written
foreach my $dir (qw(nginx httpd zimbra pveproxy)){
  if (not -d $logdir . '/' . $dir){
    make_path($logdir . '/' . $dir)
  }
}
foreach my $file (qw(syslog.log nginx/access.log nginx/error.log httpd/access.log httpd/error.log zimbra/mailbox.log)){
  open(FILE, '>', $logdir . '/' . $file);
  print FILE '';
  close FILE;
}

# List of syslog_identifier we're not intersted in
my @ignored_syslog_id = qw(
  c-icap
  charon
  unbound
  sudo
  zed
  zimbramon
  systemd
  systemd-logind
  CROND
  ttrss_1
  turnserver
  syncoid
  influxd
);
# List of log files we're not interested in
my @ignored_log_files = qw(
  /var/log/audit/audit.log
  /var/log/squid/cache.log
  /var/log/squid/access.log
  /var/log/ufdbGuard/ufdbguardd.log
  /opt/zimbra/log/gc.log
  /var/log/samba/json/auth.log
  /var/log/samba/json/dsdb.log
  /var/log/samba/json/dsdb_password.log
  /var/log/samba/json/dsdb_transaction.log
);

print "Start listening on UDP port $port\n";
$sock = IO::Socket::INET->new(
          LocalPort => $port,
          Proto => 'udp'
        ) or die("Socket: $@");

my $buf;
my $cnt = {};
my $loghandles = {};

while (1) {
  $sock->recv($buf, $maxlen);
  my ($port, $ipaddr) = sockaddr_in($sock->peername);
  my $fields = {};

  # We're not really interested in CEF headers. So let's extract
  # the various fields
  $buf =~ m/(?:(?:CEF:\d+\|)(?:[^=\\]+\|)+)(.*)/;
  my $ext = $1;

  # Taken from https://github.com/DavidJBianco/pycef
  while ($ext =~ m/([^=\s]+)=((?:[\\]=|[^=])+)(?:\s|$)/g) {
    $fields->{$1} = $2;
    # Unescape value string
    $fields->{$1} =~ s/\\=/=/g;
  }

  # Skip lines we're not interested in early.
  # So crowdsec will eat less CPU parsing useless stuff
  if (
       defined $fields->{syslog_identifier} and grep { $_ eq $fields->{syslog_identifier} } @ignored_syslog_id or
       defined $fields->{log_file_path} and grep { $_ eq $fields->{log_file_path} } @ignored_log_files
     ) {
    next;
  }

  # We need a timestamp, a source and a msg at least
  if (not defined $fields->{timestamp} or not defined $fields->{source} or not defined $fields->{msg}){
    next;
  }

  my $msg;
  # Default log will be syslog
  my $logfile = $logdir . '/syslog.log';

  # But for some services, we need special handling. Eg for web access logs
  if (defined $fields->{event_dataset}){
    if ($fields->{event_dataset} =~ m/^nginx\.(access|ingress_controller)/){
      $logfile = $logdir . '/nginx/access.log';
      $msg = $fields->{msg};
    } elsif ($fields->{event_dataset} =~ m/^nginx\.error/){
      $logfile = $logdir . '/nginx/error.log';
      $msg = $fields->{msg};
    } elsif ($fields->{event_dataset} =~ m/^apache\.access/){
      $logfile = $logdir . '/httpd/access.log';
      $msg = $fields->{msg};
    } elsif ($fields->{event_dataset} =~ m/^apache\.error/){
      $logfile = $logdir . '/httpd/access.log';
      $msg = $fields->{msg};
    }
  } elsif (defined $fields->{log_file_path}){
    if ($fields->{log_file_path} eq '/var/log/pveproxy/access.log'){
      $logfile = $logdir . '/pveproxy/access.log';
      $msg = $fields->{msg};
    } elsif ($fields->{log_file_path} eq '/opt/zimbra/log/nginx.access.log'){
      $logfile = $logdir . '/nginx/access.log';
      $msg = $fields->{msg};
    } elsif ($fields->{log_file_path} eq '/opt/zimbra/log/mailbox.log'){
      $logfile = $logdir . '/zimbra/mailbox.log';
      $msg = $fields->{msg};
    }
  } elsif (defined $fields->{application_name}){
    if ($fields->{application_name} eq 'nginx'){
      $logfile = $logdir . '/nginx/access.log';
      $msg = $fields->{msg};
    }
  }

  # OK, no special handling (else $msg would be defined), so let's
  # provide a syslog format
  if (not defined $msg){
    $msg .= $fields->{timestamp} . ' ' . $fields->{source} . ' ';
    my $id = $fields->{syslog_identifier} || $fields->{program} || $fields->{application_name} || $fields->{process_name} || 'unknown';
    # For older PfSense, which sent invalid syslog messages, we might extract
    # the syslog identifier from the begining of the message
    if ($id eq 'unknown' and $fields->{msg} =~ m/^(\w+(\[\d+\])?):\s(.*)/){
      $id = $1;
      $fields->{msg} = $3;
    }
    $msg .= $id;
    # Try to append the pid of the process
    if ($id ne 'kernel' and $id ne 'filterlog' and $id !~ m/\[\d+\]$/){
      $msg .= '[';
      $msg .= $fields->{process_pid} || $fields->{process_id} || $fields->{pid} || '0';
      $msg .= ']';
    }
    $msg .= ': ' . $fields->{msg};
  }

  defined $loghandles->{$logfile} or open($loghandles->{$logfile}, ">>", $logfile);
  # Truncate the file so it's not growing too large
  # Crowdsec will read it in nearly real time anyway
  if ($cnt->{$logfile}++ > $maxlines){
    print "Truncating $logfile\n";
    truncate $loghandles->{$logfile}, 0;
    $cnt->{$logfile} = 0;
  }
  print { $loghandles->{$logfile} } $msg . "\n";
  $loghandles->{$logfile}->flush;
};
