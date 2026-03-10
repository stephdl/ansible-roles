# G2CS

This is a small daemon writtent in perl to allow a bridge between Graylog and Crowdsec.
This idea is that if you collect your logs to a graylog instance, you can forward them all in a single stream from Graylog to CrowdSec, instead of collecting them all again on every hosts.

So, this small g2cs daemon is a very simple perl utility which will listen on a port for a syslog stream. It should run a the server which will host your single crowdsec instance.

On graylog, you have to install the syslog-output plugin, and configure it to output the streams you want to this daemon. You should choose UDP, the port on which g2cs binds, and the CEF format.

When g2cs receive this stream of logs, it'll just make simple transformations so that your logs can be consumed by crowdsec :

  * nginx logs go to nginx/
  * httpd logs go to httpd/
  * squid logs go to squid/
  * Everything else goes to syslog.log

Now, you can configure your acquisitions on crowdsec to just read these locations
