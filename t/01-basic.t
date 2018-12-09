use v6.c;
use Test;
use ResourceExtractor;
use OpenSSL;

pass "replace me";

my %local-resources := expose-resources();
say introspect-resources(%local-resources);
say virtual-io(%local-resources);

my $installed-resources = get-resources-from('OpenSSL');
say introspect-resources($installed-resources);
say virtual-io(OpenSSL);


# diag "OpenSSL";
# my $openssl = get-resources-dir(
#     :module<OpenSSL>
# );
# say $openssl;
# say $openssl.dir;

# diag "ResourceExtractor";
# my $re = get-resources-dir(
#     :module<ResourceExtractor>
# );
# say $re;
# say $re.dir;

done-testing;
