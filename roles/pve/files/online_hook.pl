#!/usr/bin/perl -w

use strict;
use warnings;
use File::Basename;
use JSON;
use Logger::Syslog;

$SIG{CHLD} = 'IGNORE';

info( "GUEST HOOK: " . join( ' ', @ARGV ) );

my $vmid = shift;
my $phase = shift;

if ( not -l '/etc/pve/local' ) {
  error( "Can't find /etc/pve/local link" );
  die;
} elsif ( not defined $vmid or not defined $phase ) {
  error( "Need to pass both vmid and phase arguments" );
  die;
} elsif ( $vmid !~ m/^\d+$/ ) {
  error( "vmid must be only numerical" );
  die;
}

# We must identify the local node
my $local_node = basename( readlink( '/etc/pve/local' ) );

if ( $phase eq 'pre-start' ) {
  info( "Runing pre-start hook for guest $vmid" );
} elsif ( $phase eq 'post-start' ) {
  info( "Running post-start hook for guest $vmid" );
  # A VM has just started. Let's check if it's already on the local node
  # If it's an incoming live migration, it might still be running on another node
  # All of this must run in the background because hooks are synchronous
  my $pid = fork();
  if ( $pid != 0 ) {
    # main script can stop now, everything will run in a forked process
    POSIX::_exit 0;
  } elsif ( defined $pid ) {
    # All those fh must be closed for the fork to be independant of its parent
    close STDOUT;
    close STDERR;
    close STDIN;
    POSIX::setsid();

    my $i = 0;
    my $guest_found = 0;

    # We'll loop for up to 30min, which should be sufficient. If migration takes longer than that,
    # something is probably wrong
    LOOP: while ( $i lt 1800 ) {
      # Here, we query the API for all the VM
      my $resources = from_json( qx(pvesh get /cluster/resources --type=vm --output-format=json) );
      # Then we loop through all the VM to find the one we're interested in
      foreach my $vm ( @{$resources} ){
        next if ( $vm->{id} !~ m{^(qemu|lxc)/$vmid$} );

        # OK, we found the guest $vmid
        info("Found guest $vmid, running on node " . $vm->{node});
        $guest_found = 1;

        # Is the guest running on local node ? If yes, it means migration is finished, and we
        # can redirect IP failover and routing table
        if ( $vm->{node} eq $local_node ) {

          # pve-online use this env var to check if we must unplug/replug the WAN NIC
          $ENV{PVE_GUEST_TYPE} = $1;

          # And here we go !
          qx(/bin/systemd-cat /usr/local/bin/pve-online --update-routes --update-gre --migrate-ipfo=$vmid);

          # Update routing table of the other online nodes
          my $nodes = from_json( qx(pvesh get /nodes --output-format=json) );
          foreach my $node ( @{$nodes} ) {
            if ( $node->{status} eq 'online' and $node->{node} ne $local_node ) {
              info("Updating routing table of node $node->{node}");
              qx(ssh -o ConnectTimeout=3 -l root $node->{node} /usr/local/bin/pve-online --update-routes);
            }
          }

          # And we're done, stop looping
          last LOOP;

        # Guest is not running on the local node = migration is still running
        # Wait a bit and start again
        } else {
          info( "Guest $vmid is still running on node " . $vm->{node} . " not yet on $local_node. Waiting a bit more for migration to finish" );
          sleep 1;
          next LOOP;
        }
      }

      # We looped through all the guests and couldn't find the one we're looking for, nothing more we can do
      if ( not $guest_found ) {
        error( "No such guest with id $vmid" );
        die;
      }
    }
  }
} elsif ( $phase eq 'pre-stop' ) {
  info( "Running pre-stop hook" );
} elsif ( $phase eq 'post-stop' ) {
  info( "Running post-stop hook" );
  # Just remove routes if needed
  qx(/bin/systemd-cat /usr/local/bin/pve-online --update-routes)
} else {
  error( "Unknown hook phase : $phase" );
  die;
}
