use v6.c;
use Test;
use ResourceExtractor;

pass "replace me";

diag "OpenSSL";
my $openssl = get-resources-dir(
    :module<OpenSSL>
);
say $openssl;
say $openssl.dir;

diag "ResourceExtractor";
my $re = get-resources-dir(
    :module<ResourceExtractor>
);
say $re;
say $re.dir;

done-testing;
