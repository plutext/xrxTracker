xquery version "3.0";

(: 
 : Main controller.
 :)
import module namespace issues="http://plutext.org/eXist/xrxTracker" at "modules/xrxTracker.xql";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>

else if ($exist:path eq "/xrxTracker-xsltforms.xhtml") then

    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
       <view>
          <forward servlet="XSLTServlet">
             (: Apply xsltforms.xsl stylesheet :)
             <set-attribute name="xslt.stylesheet" value="http://localhost:8080/exist/rest/db/apps/xrxTracker/xsltforms/xsltforms.xsl"/>
             <set-attribute name="xslt.output.omit-xml-declaration" value="yes"/>
             <set-attribute name="xslt.output.indent" value="no"/>
             <set-attribute name="xslt.output.media-type" value="text/html"/>
             <set-attribute name="xslt.output.method" value="xhtml"/>
             <set-attribute name="xslt.baseuri" value="xsltforms/"/>
          </forward>
       </view>
       <cache-control cache="no"/>
    </dispatch>
    
else if ($exist:path eq "/") then
    (: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="xrxTracker-betterFORM.xhtml?restxq={request:get-context-path()}/restxq/"/>
    </dispatch>
    
else if (ends-with($exist:resource, ".html")) then
    (: the html page is run through view.xql to expand templates :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </view>
		<error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>
    
(: Resource paths starting with $shared are loaded from the shared-resources app :)
else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>
