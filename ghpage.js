#!/usr/bin/env node

const Git = require('gh-pages/lib/git');
const filenamify = require('filenamify-url');
const copy = require('gh-pages/lib/util').copy;
const getUser = require('gh-pages/lib/util').getUser;
const fs = require('fs-extra');
const globby = require('globby');
const path = require('path');
const util = require('util');

const log = util.debuglog('gh-pages');


function getRepo(options) {
  if (options.repo) {
    return Promise.resolve(options.repo);
  } else {
    const git = new Git(process.cwd(), options.git);
    return git.getRemoteUrl(options.remote);
  }
}

function getCacheDir() {
  // return path.relative(process.cwd(), path.resolve(__dirname, '../.cache'));
  return '/tmp/gh-pages/.cache'
}

function publish(basePath, config, callback) {
  exports.defaults = {
    dest: '.',
    add: false,
    git: 'git',
    depth: 1,
    dotfiles: false,
    branch: 'gh-pages',
    remote: 'origin',
    src: '**/*',
    only: '.',
    push: true,
    message: 'Updates',
    silent: false
  };
  const options = Object.assign({}, exports.defaults, config);


  const files = globby
    .sync(options.src, {
      cwd: basePath,
      dot: options.dotfiles
    })
    .filter(file => {
      return !fs.statSync(path.join(basePath, file)).isDirectory();
    });

  const only = globby.sync(options.only, {cwd: basePath}).map(file => {
    return path.join(options.dest, file);
  });

  userPromise = getUser();
  userPromise.then(user =>
  getRepo(options)
    .then(repo => {
      repoUrl = repo;
      const clone = path.join(getCacheDir(), filenamify(repo));
      log('Cloning %s into %s', repo, clone);
      return Git.clone(repo, clone, options.branch, options);
    })
    .then(git => {
      return git.getRemoteUrl(options.remote).then(url => {
        if (url !== repoUrl) {
          const message =
            'Remote url mismatch.  Got "' +
            url +
            '" ' +
            'but expected "' +
            repoUrl +
            '" in ' +
            git.cwd +
            '.  Try running the `gh-pages-clean` script first.';
          throw new Error(message);
        }
        return git;
      });
    })
    .then(git => {
      // only required if someone mucks with the checkout between builds
      log('Cleaning');
      return git.clean();
    })
    .then(git => {
      log('Fetching %s', options.remote);
      return git.fetch(options.remote);
    })
    .then(git => {
      log('Checking out %s/%s ', options.remote, options.branch);
      return git.checkout(options.remote, options.branch);
    })
    .then(git => {
      if (!options.add) {
        log('Removing files');
        return git.rm(only.join(' '));
      } else {
        return git;
      }
    })
    .then(git => {
      log('Copying files');
      return copy(files, basePath, path.join(git.cwd, options.dest)).then(
        function() {
          return git;
        }
      );
    })
    .then(git => {
      log('Adding all');
      return git.add('.');
    })
    .then(git => {
      if (!user) {
        return git;
      }
      return git.exec('config', 'user.email', user.email).then(() => {
        if (!user.name) {
          return git;
        }
        return git.exec('config', 'user.name', user.name);
      });
    })
    .then(git => {
      log('Committing');
      return git.commit(options.message);
    })
    .then(git => {
      if (options.tag) {
        log('Tagging');
        return git.tag(options.tag).catch(error => {
          // tagging failed probably because this tag alredy exists
          log(error);
          log('Tagging failed, continuing');
          return git;
        });
      } else {
        return git;
      }
    })
    .then(git => {
      if (options.push) {
        log('Pushing');
        return git.push(options.remote, options.branch);
      } else {
        return git;
      }
    })
    .then(
      () => callback(),
      error => {
        if (options.silent) {
          error = new Error(
            'Unspecified error (run without silent option for detail)'
          );
        }
        callback(error);
      }
    )
  );

}

publish('./doc/man', {}, function(err) {
  if (err) console.log(err);
});

