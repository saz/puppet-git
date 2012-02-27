# handle git checkouts from a repository

# set up known_hosts and identities outside of this module

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
            command     => "git fetch -a && git pull && git checkout $commit && git submodule init && git submodule update --recursive && git rev-parse HEAD > ../commit",
            unless      => "test x$commit == `cat ../commit`",
            refreshonly => false,
            logoutput   => on_failure,
            require     => [
                Exec["git-clone-$directory"],
#                File["$directory/$checkoutdir"],
            ]
    }
}
