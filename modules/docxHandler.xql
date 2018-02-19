xquery version "3.1";

module namespace docxHandler="http://plutext.org/eXist/xrxTracker/docxHandler";

declare variable $docxHandler:files := "/db/apps/xrxTracker/data/files"; 

(:  fill this in to do something which suits your app  :)
declare 
    %rest:GET
    %rest:path("/docx/{$filename}")
    %rest:produces("application/xml", "text/xml")
function docxHandler:get-docx($filename as xs:string*) {
    <html><body><p>{$filename}</p></body></html>
};
