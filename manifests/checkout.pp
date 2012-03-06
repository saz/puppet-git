# handle git checkouts from a repository

# set up known_hosts and identities outside of this module

# = Define: git::checkout
#
# This class maintains a git checkout from a repository.
# known_hosts and ssh identities should be set up properly
#
# == Parameters:
#
# $directory::   The directory in which to run the initial clone command.
#                This define will drop a file called 'commit' to track the
#                last requested commit to avoid updates.
# $checkoutdir:: The directory to clone into.  You can use '.' to have it
#                go in $directory.
# $repository::  The URL to the repository.
# $user::        The user to clone or update as
# $commit::      The commit hash or tag to check out
#
# == Actions:
#   Clone and checkout or update to a given commit or tag.
#
# == Sample Usage:
# 
#   git::checkout {'linux kernel':
#       directory => '/usr/src',
#       checkoutdir => 'linux',
#       repository => 'git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux-2.6.git',
#     commit => 'v3.2',
#   }
#
define git::checkout (
    $directory, $checkoutdir, $repository,
    $user=undef, $commit='master') {

    include git::install

    file {
        "$directory":
            ensure  => directory,
            mode    => 0755,
            owner   => $user,
    }

    $allrequire = [
        File["$directory"],
        Class['git::install'],
    ]

    if ($user) {
        $require = [$allrequire, User[$user], ]
    } else {
        $require = [$allrequire, ]
    }

    # only run if the .git directory does not exist
    exec {
        "git-clone-$directory":
            cwd         => $directory,
            user        => $user,
            path        => [ "/bin", "/usr/bin", ],
            command     => "git clone --recursive $repository $checkoutdir && cd $checkoutdir && git checkout $commit",
            creates     => "$directory/$checkoutdir",
            refreshonly => false,
            logoutput   => on_failure,
            require     => $require,
    }

    # FIXME: only run if the commit is given and different from current checkout
    # FIXME: but if we check out a branch, always fetch and update
    # FIXME: if it's a branch, we need to do git pull too
    exec {
        "git-checkout-$directory":
            cwd         => "$directory/$checkoutdir",
            user        => $user,
            path        => [ "/bin", "/usr/bin", ],
            # if the previous checkout was a tag, it's not a branch, so git pull
            # fails; so break the && chain, but fetch again
            command     => "git fetch -a && git pull; git fetch -a && git checkout $commit && git submodule init && git submodule update --recursive && git rev-parse HEAD > ../commit",
            unless      => "test x$commit == `cat ../commit` || git tag --contains `cat ../commit` | grep $commit",
            refreshonly => false,
            logoutput   => on_failure,
            require     => [
                Exec["git-clone-$directory"],
#                File["$directory/$checkoutdir"],
            ]
    }
}
