# handle git checkouts from a repository

# set up known_hosts and identities outside of this module

define git::checkout ($directory, $repository, $user=undef, $commit='master') {

    file {
        "$directory":
            ensure  => directory,
            mode    => 0755,
            owner   => $user,
    }

    $allrequire = [
        File["$directory"],
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
            command     => "/usr/bin/git clone --recursive $repository .",
            creates     => "$directory/.git",
            refreshonly => false,
            logoutput   => on_failure,
            require     => $require,
    }

    # always run
    # FIXME: make recursive
    exec {
        "git-pull-$directory":
            cwd         => $directory,
            user        => $user,
            command     => "/usr/bin/git pull; /usr/bin/git submodule init; /usr/bin/git submodule update",
            refreshonly => false,
            logoutput   => on_failure,
            require     => $require,
    }

    # FIXME: only run if the commit is given and different from current checkout
    exec {
        "git-checkout-$directory":
            cwd         => $directory,
            user        => $user,
            command     => "/usr/bin/git checkout $commit",
            # unless      => " ",
            refreshonly => false,
            logoutput   => on_failure,
            require     => Exec["git-pull-$directory"],
    }
}
