FROM httpd:2.4-alpine

# Silences "AH00558: Could not reliably determine the server's fully qualified
# domain name" on every start, and hides the exact version in the Server header.
RUN printf 'ServerName localhost\nServerTokens Prod\n' >> /usr/local/apache2/conf/httpd.conf

# The official image serves /usr/local/apache2/htdocs. Replace its "It works!" page.
COPY public-html/ /usr/local/apache2/htdocs/

EXPOSE 80
# CMD is inherited from the base image: httpd-foreground
