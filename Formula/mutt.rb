# Note: Mutt has a large number of non-upstream patches available for
# it, some of which conflict with each other. These patches are also
# not kept up-to-date when new versions of mutt (occasionally) come
# out.
#
# To reduce Homebrew's maintenance burden, new patches are not being
# accepted for this formula. We would be very happy to see members of
# the mutt community maintain a more comprehesive tap with better
# support for patches.

class Mutt < Formula
  desc "Mongrel of mail user agents (part elm, pine, mush, mh, etc.)"
  homepage "http://www.mutt.org/"
  url "https://bitbucket.org/mutt/mutt/downloads/mutt-1.6.0.tar.gz"
  mirror "ftp://ftp.mutt.org/pub/mutt/mutt-1.6.0.tar.gz"
  sha256 "29afb6238ab7a540c0e3a78ce25c970f975ab6c0f0bc9f919993aab772136c19"

  bottle do
    revision 1
    sha256 "06e06c5aa69200dc8070f870faf1267e94e93a06fbbe19c56809ad8c87338970" => :el_capitan
    sha256 "95765c32a076db6f7732217c1c667ca4d9a8157355f5c075b3912b6a2e7321f4" => :yosemite
    sha256 "81ff19dbdfa6ea08be29388cde8ebdff19b128b51d6557ea0e42e8afadb02350" => :mavericks
  end

  head do
    url "https://dev.mutt.org/hg/mutt#default", :using => :hg

    resource "html" do
      url "https://dev.mutt.org/doc/manual.html", :using => :nounzip
    end
  end

  conflicts_with "tin",
    :because => "both install mmdf.5 and mbox.5 man pages"

  option "with-debug", "Build with debug option enabled"
  option "with-s-lang", "Build against slang instead of ncurses"
  option "with-confirm-attachment-patch", "Apply confirm attachment patch"
  option "with-sidebar-patch", "Apply sidebar patch"
  option "with-trash-patch", "Apply trash folder patch"
  option "with-ignore-thread-patch", "Apply ignore-thread patch"
  option "with-pgp-verbose-mime-patch", "Apply PGP verbose mime patch"

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  depends_on "openssl"
  depends_on "tokyo-cabinet"
  depends_on "gettext" => :optional
  depends_on "gpgme" => :optional
  depends_on "libidn" => :optional
  depends_on "s-lang" => :optional

  if build.with? "confirm-attachment-patch"
    patch do
      url "https://gist.githubusercontent.com/tlvince/5741641/raw/c926ca307dc97727c2bd88a84dcb0d7ac3bb4bf5/mutt-attach.patch"
      sha256 "da2c9e54a5426019b84837faef18cc51e174108f07dc7ec15968ca732880cb14"
    end
  end

  if build.with? "sidebar-patch" 
    patch do
      url "http://ftp.fr.openbsd.org/pub/OpenBSD/distfiles/mutt/sidebar-1.6.0.diff.gz"
      sha256 "63b6b28d7008b6d52bd98151547b052251cd4bc87e467e47ffebe372dfe7155b"
  end

  if build.with? "trash-patch"
    patch do
     url "http://ftp.fr.openbsd.org/pub/OpenBSD/distfiles/mutt/trashfolder-1.6.0.diff.gz"
     sha256 "b779c6df61a77f3069139aad8562b4a47c8eed8ab5b8f5681742a1c2eaa190b8"
  end 

  # original source for this went missing, patch sourced from Arch at
  # https://aur.archlinux.org/packages/mutt-ignore-thread/
  if build.with? "ignore-thread-patch"
    patch do
     url "https://gist.githubusercontent.com/mistydemeo/5522742/raw/1439cc157ab673dc8061784829eea267cd736624/ignore-thread-1.5.21.patch"
     sha1 "dbcf5de46a559bca425028a18da0a63d34f722d3"
  end 

  if build.with? "pgp-verbose-mime-patch"
   patch do
     url "http://patch-tracker.debian.org/patch/series/dl/mutt/1.5.21-6.2+deb7u1/features-old/patch-1.5.4.vk.pgp_verbose_mime"
     sha1 "a436f967aa46663cfc9b8933a6499ca165ec0a21"
   end 

  def install
    user_admin = Etc.getgrnam("admin").mem.include?(ENV["USER"])

    args = %W[
      --disable-dependency-tracking
      --disable-warnings
      --prefix=#{prefix}
      --with-ssl=#{Formula["openssl"].opt_prefix}
      --with-sasl
      --with-gss
      --enable-imap
      --enable-smtp
      --enable-pop
      --enable-hcache
      --with-tokyocabinet
    ]

    # This is just a trick to keep 'make install' from trying
    # to chgrp the mutt_dotlock file (which we can't do if
    # we're running as an unprivileged user)
    args << "--with-homespool=.mbox" unless user_admin

    args << "--disable-nls" if build.without? "gettext"
    args << "--enable-gpgme" if build.with? "gpgme"
    args << "--with-slang" if build.with? "s-lang"

    if build.with? "debug"
      args << "--enable-debug"
    else
      args << "--disable-debug"
    end

    system "./prepare", *args
    system "make"

    # This permits the `mutt_dotlock` file to be installed under a group
    # that isn't `mail`.
    # https://github.com/Homebrew/homebrew/issues/45400
    if user_admin
      inreplace "Makefile", /^DOTLOCK_GROUP =.*$/, "DOTLOCK_GROUP = admin"
    end

    system "make", "install"
    doc.install resource("html") if build.head?
  end

  test do
    system bin/"mutt", "-D"
  end
end
