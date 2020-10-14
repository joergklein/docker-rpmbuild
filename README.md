# Docker base image to build RPM files for CentOS

Sometimes you might have access to an open source application source code but
might not have the RPM file to install it on your system. In that situation, you
can either compile the source code and install the application from source code,
or build a RPM file from source code yourself, and use the RPM file to install
the application.

There might also be a situation where you want to build a custom RPM package for
the application that you developed. In order to build RPMs, you will need
source code, which usually means a compressed tar file that also includes the
SPEC file. The SPEC file typically contains instructions on how to build RPM,
what files are part of package and where it should be installed.

### The RPM performs the following tasks during the build process.

1. Executes the commands and macros mentioned in the prep section of the spec
   file.
2. Checks the content of the file list
3. Executes the commands and macros in the build section of the spec file.
   Macros from the file list is also executed at this step.
4. Creates the binary package file
5. Creates the source package file

Once the RPM executes the above steps, it creates the binary package file and
source package file.

It is usually enabled with all the options for installing the package that are
platform specific. Binary package file contain complete applications or
libraries of functions compiled for a particular architecture. The source
package usually consists of the original compressed tar file, spec file and the
patches which are required to create the binary package file.

Let us see how to create a simple source and BIN RPM packages using a tar file.

## 10 Steps to Build a RPM Package from Source on CentOS / RedHat.

### 1. Install rpm-build Package

To build an rpm file based on the spec file that we just created, we need to use
rpmbuild command.

### 2. RPM Build Directories

rpm-build will automatically create the following directory structures that will
be used during the RPM build.

```sh
# ls -lF /root/rpmbuild/
drwxr-xr-x. 2 root root 4096 Okt  4 12:21 BUILD/
drwxr-xr-x. 2 root root 4096 Okt  4 12:21 BUILDROOT/
drwxr-xr-x. 2 root root 4096 Okt  4 12:21 RPMS/
drwxr-xr-x. 2 root root 4096 Okt  4 12:21 SOURCES/
drwxr-xr-x. 2 root root 4096 Okt  4 12:21 SPECS/
drwxr-xr-x. 2 root root 4096 Okt  4 12:21 SRPMS/
```

**Note**: The above directory structure is for both CentOS and RedHat when using
rpmbuild package. You can also use /usr/src/redhat directory, but you need to
change the topdir parameter accordingly during the rpm build. If you are doing
this on SuSE Enterprise Linux, use /usr/src/packages directory.

If you want to use your own directory structure instead of the /root/rpmbuild,
you can use one of the following option:

- Use –buildroot option and specify the custom directory during the rpmbuild
- Specify the topdir parameter in the rpmrc file or rpmmacros file.

### 3. Download Source Tar File

Next, download the source tar file for the package that you want to build and
save it under SOURCES directory.

For this example, I’ve used the source code of hello open source application,
which is a server software for streaming multi-media. But, the steps are exactly
the same for building RPM for any other application. You just have to download
the corresponding source code for the RPM that you are trying to build.

```sh
# cd /root/rpmbuild/SOURCES/
# curl -LJO http://ftp.gnu.org/gnu/hello/hello-2.10.tar.gz
# ls -l
-rw-r--r--. 1 root root 725946 Oct 14 09:01 hello-2.10.tar.gz
```

### 4. Create the SPEC File

In this step, we direct RPM in the build process by creating a spec file. The
spec file usually consists of the following eight different sections:

1. `Preamble` – The preamble section contains information about the package
   being built and define any dependencies to the package. In general, the
   preamble consists of entries, one per line, that start with a tag followed by
   a colon, and then some information.

2. `%prep` – In this section, we prepare the software for building process. Any
   previous builds are removed during this process and the source file(.tar)
  file is expanded, etc.

3. One more key thing is to understand there are pre-defined macros available to
   perform various shortcut options to build rpm. You may be using this macros
   when you try to build any complex packages. In the below example, I have used
   a macro called `%setup` which removes any previous builds, untar the source
   files and changes the ownership of the files. You can also use sh scripts
   under `%prep` section to perform this action but %setup macro simplifies the
   process by using predefined sh scripts.

4. `%description` – the description section usually contains description about
   the package.

5. `%build` – This is the section that is responsible for performing the build.
   Usually the %build section is an sh script.

6. `%install` – the `%install` section is also executed as sh script just like
   `%prep` and `%build`. This is the step that is used for the installation.

7. `%files` – This section contains the list of files that are part of the
   package. If the files are not part of the `%files` section then it wont be
   available in the package. Complete paths are required and you can set the
   attributes and ownership of the files in this section.

8. `%clean` – This section instructs the RPM to clean up any files that are not
   part of the application’s normal build area. Lets say for an example, If the
   application creates a temporary directory structure in /tmp/ as part of its
   build, it will not be removed. By adding a sh script in `%clean` section, the
   directory can be removed after the build process is completed.

Here is the SPEC file that was created for the hello application to build an RPM
file.

```sh
Name:           hello
Version:        2.10
Release:        1%{?dist}
Summary:        The "Hello World" program from GNU

License:        GPLv3+
URL:            http://ftp.gnu.org/gnu/%{name}
Source0:        http://ftp.gnu.org/gnu/%{name}/%{name}-%{version}.tar.gz

BuildRequires: gettext

Requires(post): info
Requires(preun): info

%description
The "Hello World" program, done with all bells and whistles of a proper FOSS
project, including configuration, build, internationalization, help files, etc.

%prep
%autosetup

%build
%configure
%make_build

%install
%make_install
%find_lang %{name}
rm -f %{buildroot}/%{_infodir}/dir

%post
/sbin/install-info %{_infodir}/%{name}.info %{_infodir}/dir || :

%preun
if [ $1 = 0 ] ; then
/sbin/install-info --delete %{_infodir}/%{name}.info %{_infodir}/dir || :
fi

%files -f %{name}.lang
%{_mandir}/man1/hello.1.*
%{_infodir}/hello.info.*
%{_bindir}/hello

%doc AUTHORS ChangeLog NEWS README THANKS TODO
%license COPYING

%changelog
* Tue Sep 06 2011 The Coon of Ty <Ty@coon.org> 2.10-1
- Initial version of the package
```

In `%build` section, you will see the CFLAGS with configure options that defines
the options that can be using during RPM installation and the prefix option ,
mandatory directory to be present for the installation and sysconfig directory
under which the system files needs to be copied over.

Below that line, you will see the make utility which determines the list of
files needs to be compiled and compiles them appropriately.

In `%install` section, the line below the %install that says “make install” is
used to take the binaries compiled from the previous step and installs or copies
them to the appropriate locations so they can be accessed.

### 5. Create the RPM File using rpmbuild

Once the SPEC file is ready, you can start building your rpm with rpm –b
command. The –b option is used to perform all the phases of the build process.
If you see any errors during this phase, then you need to resolve it before
re-attempting again. The errors will be usually of library dependencies and you
can download and install it as necessary.

```sh
# cd /root/rpmbuild/SPECS
# rpmbuild -ba hello.spec
```

### 6. rpmlint

Next you should check them for conformance with RPM design rules, by running
`rpmlint` on the `.spec` file and all RPMs:

```sh
# rpmlint hello.spec ../SRPMS/hello* ../RPMS/*/hello*
```

If there are no warnings or errors, we've succeeded. Otherwise, use `rpmlint -i`
or `rpmlint -I <error_code>` to see a more verbose description of the `rpmlint
diagnostics`.


### 7. Verify the Source and Binary RPM Files

Once the rpmbuild is completed, you can verify the source rpm and binary rpm is
created in the below directories.

```sh
# ls -l /root/rpmbuild/SRPMS/
-rw-r--r--. 1 root root 733140 Oct 14 09:06 hello-2.10-1.el8.src.rpm
-rw-r--r--. 1 root root 732840 Oct 14 09:04 hello-2.10-1.src.rpm

# ls -l /root/rpmbuild/RPMS/x86_64/
-rw-r--r--. 1 root root 80744 Oct 14 09:06 hello-2.10-1.el8.x86_64.rpm
-rw-r--r--. 1 root root 40868 Oct 14 09:06 hello-debuginfo-2.10-1.el8.x86_64.rpm
-rw-r--r--. 1 root root 47956 Oct 14 09:06 hello-debugsource-2.10-1.el8.x86_64.rpm
```

### 8. Install the RPM File to Verify

As a final step, you can install the binary rpm to verify that it installs
successfully and all the dependencies are resolved.

```sh
# rpm -ivvh /root/rpmbuild/RPMS/x86_64/hello-2.10-1.el8.x86_64.rpm
```

After the above installation, you can verify that your custom created rpm file
was installed successfully as shown below.

```sh
# rpm -qa hello
hello-2.10-1.el8.x86_64
```

**Type hello and you get Hello, world!**

### 9. Check if hello is installed with dnf

```sh
# dnf install hello

Last metadata expiration check: 0:02:59 ago on Wed Oct 14 09:26:49 2020.
Package hello-2.10-1.el8.x86_64 is already installed.
Dependencies resolved.
Nothing to do.
Complete!
```

### 10. Remove hello with dnf

```sh
# dnf remove hello

Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                             1/1
  Running scriptlet: hello-2.10-1.el8.x86_64     1/1
  Erasing          : hello-2.10-1.el8.x86_64     1/1
  Running scriptlet: hello-2.10-1.el8.x86_64     1/1
  Verifying        : hello-2.10-1.el8.x86_64     1/1

Removed:
  hello-2.10-1.el8.x86_64

Complete!

```

