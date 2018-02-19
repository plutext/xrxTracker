# xrxTracker
A bug/enhancement/issue/task tracker in exist-db, using XForms, RESTXQ and XQuery (XRX)

Current status: proof of concept, not production ready!

The issues are stored in eXist.

## Issue XML format

For an idea of this, see https://github.com/plutext/xrxTracker/blob/master/xrxTracker-xsltforms.xhtml#L34

## Motivation and Features

My motivation for creating this was that file attachments that happen to be XML can
be stored as XML, so you can take advantage of the power of eXist (eg apply XQueries to them).
This also applies to zip attachments which contain XML (these are unzipped).

Forgetting about eXist for a moment, some years ago there was some interest in distributed bug trackers: why not store
your issues in Git?  Could we use xsltforms to make this work nicely (ie a user interface for viewing an issue or
creating a new one)?

## Status/TODO

* save issue as logged in user 
* beautify with CSS
* support deletion (by just making the issue empty)
* replace hardcoded URLs

Pull requests gratefully accepted

## Installation

Pre-reqs: 
* JoeWiz's unzip: https://github.com/joewiz/unzip
* FuncX (in eXist's package manager, you need it for unzip above anyway)

Create the xar

Install the xar in eXist

Fix URLs, dir permissions etc as necessary (TODO)

Then see client (eg Orbeon or xsltforms) specific config.


## XForm clients

You can use your preferred XForms implementation:

* betterForm (the default, no configuration required)
* Orbeon
* xsltforms 

Since these all require slightly differing XForms, the current approach is to have a different
XForm for each implementation:

* xrxTracker-betterFORM.xhtml
* xrxTracker-Orbeon.xhtml, https://github.com/plutext/xrxTracker/blob/master/client-Orbeon/xforms-xrxTracker/xrxTracker-Orbeon.xhtml
* xrxTracker-xsltforms.xhtml, https://github.com/plutext/xrxTracker/blob/master/xrxTracker-xsltforms.xhtml

### betterForm

http://localhost:8080/exist/apps/xrxTracker/

### Orbeon

http://localhost:8081/orbeon/xforms-xrxTracker/
 
I used two servers:

1.  Orbeon in Tomcat
1.  standalone eXist server

The user loads the form from the Orbeon instance: http://localhost:8081/orbeon/xforms-xrxTracker/

but the issues are stored in the standalone eXist server, and all the RestXQ calls point there.

To use Orbeon, copy to webapps/orbeon/WEB-INF/resources/apps/xforms-xrxTracker/ the following:

client-orbeon/xforms-xrxTracker

then edit the URLs in xrxTracker-Orbeon.xhtml to point to your eXist instance.


### xsltforms

http://localhost:8080/exist/apps/xrxTracker/xrxTracker-xsltforms.xhtml

To use xsltforms, disable betterForm: http://exist-db.org/exist/apps/doc/xforms.xml#D1.4.12

System global by editing $EXIST_HOME/webapp/WEB-INF/betterform-config.xml:

<property name="filter.ignoreResponseBody" value="true">

At present xrxTracker includes its own copy of xsltforms.

This is because:

1.  I couldn't figure out how to re-use eXist's copy (using a static XForm, which I prefer)

2.  It is patched so that file uploads work (although the filename is lost)

How it works: controller.xql contains:

```
if ($exist:path eq "/xrxTracker-xsltforms.xhtml") then

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
       <view>
          <forward servlet="XSLTServlet">
             (: Apply xsltforms.xsl stylesheet :)
             <set-attribute name="xslt.stylesheet" value="http://localhost:8080/exist/rest/db/apps/xrxTracker/xsltforms/xsltforms.xsl"/>
             :
```

## Troubleshooting

You might need to register modules:

```
    import module namespace restxqex = "http://exquery.org/ns/restxq/exist";

    restxqex:register-module(xs:anyURI('/db/apps/xrxTracker/modules/xrxTracker.xql'))

    restxqex:register-module(xs:anyURI('/db/apps/xrxTracker/modules/mvfile.xqm'))
```    
    
