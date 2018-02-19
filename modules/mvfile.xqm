xquery version "3.1";

module namespace f="http://plutext.org/eXist/xrxTracker/file";

import module namespace config="http://plutext.org/eXist/xrxTracker/config" at "config.xqm";
import module namespace file="http://exist-db.org/xquery/file";
import module namespace console="http://exist-db.org/xquery/console";

(: ASLv2, from https://github.com/lcahlander/bfupload/blob/master/modules/mvfile.xqm :)

import module namespace unzip = 'http://joewiz.org/ns/xquery/unzip';
import module namespace functx = 'http://www.functx.com';
import module namespace xmldb = 'http://exist-db.org/xquery/xmldb'; 
import module namespace xpath = 'http://www.w3.org/2005/xpath-functions'; 
                                
declare function f:store-document($collection-uri as xs:string,
$resource-name as xs:string, $resource-ext as xs:string, 
$contents as xs:base64Binary, $mime-type as xs:string) as element() {

    let $filename := concat($resource-name, ".", $resource-ext)
    
    return
        if ($resource-ext='docx') then
            let $itsdocx := console:log("its a docx")
            (: store the file :)
            let $stored := xmldb:store-as-binary($collection-uri, $filename, $contents)
            (: now unzip it :)
            let $zip-file := concat($collection-uri, "/", $filename)
            let $target-collection := concat($collection-uri, "/", $resource-name)
            let $action := console:log("unzip " || $zip-file || " to " || $target-collection )
            return unzip:unzip($zip-file, $target-collection) 
        else 
            let $stored := xmldb:store($collection-uri, $filename, $contents, $mime-type)
            return <file/>
};
  

    (:  move file from filesystem to eXist; works for betterform in eXist or Orbeon (in Tomcat) front ends.

    orbeon
    
        file:/media/jharrop/Overflow/apache-tomcat-8.5.27/temp/xforms_upload_6810211635002454197.tmp?filename=docProps.docx&mediatype=application/vnd.openxmlformats-officedocument.wordprocessingml.document&size=10780&mac=615900fc0e0ec8abff995a3    

      bf 
    
    <file filename="invoice.docx" 
            mediatype="application/vnd.openxmlformats-officedocument.wordprocessingml.document" size="">
            %2Fexist%2Fupload%2F1518329585457%2Finvoice.docx</file> 
            
    xsltforms, it is base64 encoded in the form:
    
        <file filename="" mediatype="" size="">UEsDBBQA..wAAgMAAAQnAAAAAA==</file>    
    :)

declare function f:isBinary($val as xs:string) as xs:boolean
{
    let $result :=
        if (xpath:starts-with($val, "file:/") or xpath:starts-with($val, "%2Fexist") ) then
            false()
        else true()
    
    return $result
};

declare function f:node-to-db($file as node(), $id as xs:string, $attachmentCount as xs:string) as node()
{
    let $val := $file/text()

    return 
        
        if ($val) then
            
            if (f:isBinary($val)) then
                let $logBinary := console:log("base64 content from xsltforms" ) 
                return system:as-user('admin', 'PASSWORD',
                
                    try {
                        let $lognode := console:log($file) 

                        return 
                                let $filesColl := concat($config:data-root, '/files')
                                
                                let $prefix := "unknown"
                                let $ext := "docx"
                                
                                let $filename := concat($id, "_", $prefix, "-", $attachmentCount)

                                let $logexfn := console:log($filename)
                                
                                let $mediatype := "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                                (: store contents :)
                                (: let $stored := xmldb:store($filesColl, $filename, $contents) :)
                                let $stored := f:store-document($filesColl, $filename, $ext, $val, $mediatype )
    
                                let $logexstored := console:log("stored " || $stored)
                                
                                (: dir or filename? :)
                                let $finalname :=
                                    if (xpath:local-name($stored)='entries') 
                                        then $filename 
                                        else concat($filename, ".", $ext)
    
                                return (                            
                                <attachment filename="{$finalname}" mediatype="{$file/@mediatype}" timestamp="{datetime:timestamp()}" storedAs="{xpath:local-name($stored)}"></attachment>   )
                                    
                    } catch * {
                        <failed/>
                    })
                
                
            else    
                let $path := util:unescape-uri($val, "UTF-8")    
                return system:as-user('admin', 'PASSWORD',
                
                    try {
                        let $lognode := console:log($file) 
                        let $logpath := console:log($path)
    
                        (: construct absolute file system path :)
                        let $file-path := if (xpath:starts-with($path, "/exist/upload"))
                            then concat('/media/jharrop/Overflow/eXist-db-4.0/webapp/upload/', 
                                            substring-after($path, 'upload/') )
                            else substring-before(
                                    substring-after($path, 'file:'), "?")
                        
                        let $vv3 := console:log($file-path)
                        let $exists := file:exists($file-path)
                        let $vv2 := console:log($exists)
                        return 
                            if ($exists) then 
                                let $vvA := console:log("in exists")
                                let $contents := file:read-binary($file-path)
                                let $filesColl := concat($config:data-root, '/files')
                                
                                let $info1 := util:log('INFO ', "storing to " || $config:data-root)
                                let $info2 := util:log('INFO ', "name " || $file/@filename )
    
    
                                let $filename0 := $file/@filename
                                let $prefix := functx:substring-before-last($filename0, '.')
                                let $ext := functx:substring-after-last($filename0, '.')
                                let $filename := concat($id, "_", $prefix, "-", $attachmentCount)
                                (: hmm exide didn't warn me that prefix (without $) was wrong, then eXist happily runs it but it doesn't work as expected :)
                                
                                let $logexfn := console:log($filename)
                                
                                (: store contents :)
                                (: let $stored := xmldb:store($filesColl, $filename, $contents) :)
                                let $stored := f:store-document($filesColl, $filename, $ext, $contents, $file/@mediatype)
    
                                let $logexstored := console:log("stored " || $stored)
                                
                                (: dir or filename? :)
                                let $finalname :=
                                    if (xpath:local-name($stored)='entries') 
                                        then $filename 
                                        else concat($filename, ".", $ext)
    
                                return (                            
                                <attachment filename="{$finalname}" mediatype="{$file/@mediatype}" timestamp="{datetime:timestamp()}" storedAs="{xpath:local-name($stored)}"></attachment>   )
                                    
                            else 
                                    <nofile/>
                    } catch * {
                        <failed/>
                    })
        else 
                <blank></blank>
        
};

