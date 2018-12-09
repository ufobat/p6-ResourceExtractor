use v6.c;
use File::Temp;
use JSON::Fast;

class IO::Resource does IO {
    has %!content;
    has $!io;

    submethod BUILD(:%content, :$io, :$ ){}

    method IO {
    }
}

module ResourceExtractor:ver<0.0.3> {

    sub expose-resources() is export { return %?RESOURCES }

    multi sub get-resources-from($module, :$version, :$api, :$auth) is export {
        return get-resources-from($module.^name, :$version, :$api, :$auth);
    }
    multi sub get-resources-from(Str:D $module, :$version, :$api, :$auth) is export {
        say "getting resources for $module";
        my $spec = CompUnit::DependencySpecification.new(
            :short-name($module),
            :version-matcher($version // True),
            :auth-matcher($auth // True),
            :api-matcher($api // True),
        );
        my $comp-unit    = $*REPO.resolve($spec);
        my $distribution = $comp-unit.distribution;
        my $repo         = $comp-unit.repo;
        my $dist-id      = $distribution.dist-id;
        my $resources    = Distribution::Resources.new(:$repo, :$dist-id);
        return $resources;
    }

    sub introspect-resources(Distribution::Resources $resources --> Hash) is export {
        my $repo = $resources.repo-name
            ?? CompUnit::RepositoryRegistry.repository-for-name($resources.repo-name)
            !! CompUnit::RepositoryRegistry.repository-for-spec($resources.repo);

        given $repo {
            when CompUnit::Repository::FileSystem {
                # FileSystem does not have a Distribution
                my $resources-dir = $_.prefix.parent.child('resources');
                my %resources-map;
                my @stack;
                my sub process-dir(IO $dir) {
                    for $dir.dir -> $cld {
                        if $cld.d {
                            @stack.push($cld.basename);
                            process-dir($cld);
                            @stack.pop;
                        } else {
                            my $resource-name = join('/', |@stack, $cld.basename);
                            %resources-map{ $resource-name } = $cld;
                        }
                    }
                };
                process-dir($resources-dir);
                return %resources-map;
            }
            when CompUnit::Repository::Installation {
                my $dist-id = $resources.dist-id;
                my $distribution := $repo.distribution($dist-id);
                my $meta  = $distribution.meta;
                my %resources-map = gather for $meta<resources>.List -> $name {
                    my $resource   = $_.resource($dist-id, 'resources/' ~ $name);
                    take $name => $resource;
                };
                return %resources-map;
            }
            default {
                die "dont know how to handle your repository {{ $_.^name  }}";
            }
        }
    }

    multi sub virtual-io($module, :$api, :$version, :$auth --> IO::Resource) is export {
        return virtual-io(get-resources-from($module, :$api, :$version, :$auth));
    }
    multi sub virtual-io(Distribution::Resources $resources --> IO::Resource) is export {
       return virtual-io(introspect-resources($resources));
    }
    multi sub virtual-io(%introspected-resources --> IO::Resource) is export {
        X::NYI.new(feature => 'virtual-io').throw;
    }

    # sub get-resources-dir(
    #     Str :$module,
    #     Str :$version,
    #     Str :$api,
    #     Str :$auth,
    #     Distribution::Resources :$resources,
    #     --> IO
    # ) is export
    # {
    #     my ($dist-id, $repo, $distribution);
    #     if %resources {
    #         $dist-id = %resources.dist-id;
    #         $repo = %resources.repo-name
    #         ?? CompUnit::RepositoryRegistry.repository-for-name(%resources.repo-name)
    #         !! CompUnit::RepositoryRegistry.repository-for-spec(%resources.repo);
    #         $distribution := $repo.distribution($dist-id);
    #     } elsif $module {
    #         my $spec = CompUnit::DependencySpecification.new(
    #             :short-name($module),
    #             :version-matcher($version // True),
    #             :auth-matcher($auth // True),
    #             :api-matcher($api // True),
    #         );
    #         my $comp-unit = $*REPO.resolve($spec);
    #         $distribution = $comp-unit.distribution;
    #         $repo         = $comp-unit.repo;
    #     } else {
    #         die 'either provide :short-name or %?RESOURCES as resources';
    #     }
    #     given $repo {
    #         when CompUnit::Repository::FileSystem {
    #             my $resources;

    #             # this is the /path/to/lib of perl6 -I/path/to/lib
    #             # so there are most likely no resources
    #             # so we check ../resources first
    #             $resources = $_.prefix.add('../resources');
    #             return $resources.resolve if $resources.e;

    #             # *shrug*
    #             $resources = $_.prefix.add('resources');
    #             return $resources if $resources.e;

    #             die "coudn't find resources in {{ $_.prefix }}";
    #         }
    #         when CompUnit::Repository::Installation {
    #             my $tempdir = tempdir().IO;
    #             my $meta    = $distribution.meta;
    #             $dist-id    //= $distribution.dist-id;
    #             for $meta<resources>.List -> $name {
    #                 my $file       = $tempdir.add($name);
    #                 my $parent-dir = $file.parent();
    #                 my $resource   = $_.resource($dist-id, 'resources/' ~ $name);
    #                 my $content    = $resource.slurp(:bin);
    #                 $parent-dir.mkdir() unless $parent-dir.e;
    #                 $file.spurt($content, :createonly);
    #             };
    #             return $tempdir;
    #         }
    #         default {
    #             die "dont know how to handle your repository {{ $_.^name  }}";
    #         }
    #     }
    # }
}

=begin pod

=head1 NAME

ResourceExtractor - blah blah blah

=head1 SYNOPSIS

  use ResourceExtractor;

=head1 DESCRIPTION

ResourceExtractor is ...

=head1 AUTHOR

Martin Barth <martin@senfdax.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Martin Barth

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
