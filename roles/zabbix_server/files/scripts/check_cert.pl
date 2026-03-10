#!/usr/bin/perl

=head1 SYNOPSIS

        check_ssl_certificate.pl
            --url,-u URL
            --sni,-s HOSTNAME               SNI servername (SSL vhost) that will be requested during SSL handshake.
                                            This tells the server which certificate to return.
                                            Default to the host passed with --url

=cut

use strict;
use warnings;
use IO::Socket::SSL;
use LWP::UserAgent;
use URI::URL;
use DateTime::Format::ISO8601;
use Getopt::Long qw/:config auto_help/;
use Pod::Usage;
use JSON qw(to_json);

use constant TIMEOUT => 10;

my ($url, $sni, $status, @san);

sub ssl_opts {
  my ($sni, $expiration_date_ref, $status_ref, $san_ref) = @_;
  return (
    'verify_hostname'     => 0,
    'SSL_ca_file'         => '/etc/pki/tls/certs/ca-bundle.crt',
    'SSL_hostname'        => $sni,
    'SSL_verifycn_name'   => $sni,
    'SSL_verify_scheme'   => 'http',
    'SSL_verify_callback' => sub {
        my (undef, $ctx_store) = @_;
        # Get the error message from openssl verification
        $$status_ref = Net::SSLeay::X509_verify_cert_error_string(Net::SSLeay::X509_STORE_CTX_get_error($ctx_store));
        # Get the raw cert, to extract the expiration
        my $cert = Net::SSLeay::X509_STORE_CTX_get_current_cert($ctx_store);
        $$expiration_date_ref = Net::SSLeay::P_ASN1_TIME_get_isotime(Net::SSLeay::X509_get_notAfter($cert));
        # Get Alt names so we can check later if the hostname match
        @$san_ref = Net::SSLeay::X509_get_subjectAltNames($cert);
        # Keep only odd elements. Even ones contains subject types which we're not interested in
        @$san_ref = @$san_ref[grep $_ % 2, 0..scalar(@$san_ref)];
        # Always return success
        return 1;
    }
  )
}

sub https_get {
  my ($url, $sni, $expiration_date_ref, $status_ref, $san_ref) = @_;

  my $ua = LWP::UserAgent->new();
  $ua->timeout(TIMEOUT);
  $ua->ssl_opts( ssl_opts($sni, $expiration_date_ref, $status_ref, $san_ref) );
  my $request = HTTP::Request->new('GET', $url);
  $request->header(Host => $sni);
  my $response = $ua->simple_request($request);
  return $response;
}

sub wildcard_match {
  my ($cn, $host) = @_;
  my $match = 0;
  return 0 if $cn !~ m/^\*\.(.*)$/;
  my $cn_dom  = $1;
  my $host_dom = ($sni =~ m/^[^\.]+\.(.*)$/)[0];
  return ($cn_dom eq $host_dom);
}

GetOptions ("url|u=s" => \$url,
            "sni|s=s" => \$sni) or pod2usage(1);
if (@ARGV) {
  print "This script takes no arguments...\n";
  pod2usage(1);
}
pod2usage(1) if (!$url);

my $expiration_date;
my $uri = URI->new($url);
die "Only https urls are supported\n" unless $uri->scheme eq 'https';
$sni ||= $uri->host;
my $response = https_get($url, $sni, \$expiration_date, \$status, \@san);

my $out = {
  code      => $response->code,
  status    => $response->message,
  days_left => undef,
  cert_cn   => undef,
  issuer    => undef
};

if ($response->code != 500) { # Even a 404 is good enough, as far as cert validation goes...
  my $now = DateTime->now;
  $expiration_date = DateTime::Format::ISO8601->parse_datetime( $expiration_date );

  $out->{issuer} = $response->headers->{'client-ssl-cert-issuer'};
  $out->{cert_cn} = ($response->headers->{'client-ssl-cert-subject'} =~ m/CN=(.*)$/)[0];
  $status = "no common name" if !$out->{cert_cn};
  $out->{status} = ($status eq 'ok' and !grep { $sni eq $_ } @san and !wildcard_match($out->{cert_cn},$sni)) ?
                      $out->{status} = "hostname mismatch ($sni doesn't match any of " . join(" ", @san) . ")" :
                      $status;
  $out->{days_left} = ($expiration_date < $now) ? -1 * $expiration_date->delta_days($now)->delta_days :
                                                       $expiration_date->delta_days($now)->delta_days
}

print to_json($out, { pretty => 1 });
