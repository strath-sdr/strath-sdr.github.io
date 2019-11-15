# Source for [strath-sdr.github.io](https://strath-sdr.github.io)

Here's the source code for the `strath-sdr` group blog. 

This is the place for anyone to contribute new posts. Visitors just wanting to
see the blog should go to [strath-sdr.github.io](https://strath-sdr.github.io)
instead.


## Contributing

Here's a few words on how to contribute to the blog.


### Adding yourself as an author

We try to automatically attach an author name and picture to each post. For this
to work, there needs to be an entry for you in `_data/authors.yml` and an image
in `assets/avatars/`.

If you want to be added to the authors list, either:

  1. Pester @cramsay to do it, or...
  2. See [this
     commit](https://github.com/strath-sdr/commit/7edc863856d0d3ab416d1a84f5e54ec906d71ba7)
     for an example of what to add.


### Writing a new post

Posts live in the `_posts` folder. See `_posts` for an example.

These are formatted with Markdown, just like any GitHub README pages. Here's a
quick, [interactive guide to writing in
Markdown](https://www.markdowntutorial.com/). Note that you can resort to
writing HTML too, if needed.

Add any images you need in a new folder for your post inside the `assets`
folder. You should be able to reference them in your post with something like
`![A title for my pic](/assets/2019-11-15/tea.jpg)`

> Obviously give some thought to the content you're posting. This is a *public*
> site that represents the group. Don't shoot yourself in the foot if you want
> to publish something similar in a paper later on...


### Previewing changes locally

So you've made some changes but would like to preview what the blog will look
like before committing it?

#### For Linux/macOS users

There's an environment already specified for you using the `nix` package
manager. This is system that will run on all Linux distros, and has very nice
deterministic properties (it's a pure functional language 😉).

First install `nix`:

```bash
$ curl https://nixos.org/nix/install | sh
```

Now just download this repo, `cd` into it and tell `nix` to do its thing:

```bash
$ nix-shell
```

This will fetch all the dependencies for Jekyll (the blog software GitHub pages
uses), set up an environment, launch Jekyll and open the blog preview in a
browser tab 🎉

#### Windows

@cramsay has a horrible Linux myopia, so there isn't (yet) such a streamline way
to preview the blog on windows. The best way is to follow a guide to [manually
install Jekyll](https://jekyllrb.com/docs/installation/windows/).

Maybe someone with Windows could help us make better instructions?


### Submitting changes

Any changes committed to the `master` branch will automatically published to
[strath-sdr.github.io](https://strath-sdr.github.io) within a few seconds,
thanks to GitHub Pages.

For any big updates (e.g. new posts or major theme changes) or things you're
unsure of, it's best to submit a [pull
request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests)
rather than committing directly to `master`. This gives a chance for others to
offer feedback before it is published to the blog.

As a rule of thumb, just ask if you're unsure! We're a friendly bunch and it
would be great if this blog sees a bit of use.
