xquery version "3.1";

module namespace f="http://plutext.org/eXist/xrxTracker/file";

import module namespace config="http://plutext.org/eXist/xrxTracker/config" at "config.xqm";
import module namespace file="http://exist-db.org/xquery/file";
import module namespace console="http://exist-db.org/xquery/console";


(: ASLv2, based on https://github.com/lcahlander/bfupload/blob/master/modules/mvfile.xqm :)


declare function f:node-to-db($file as node(), $id as xs:string, $attachmentCount as xs:string) as node()
{
    let $uri := $file/text()

    return 
        
        if ($uri) then
            let $path := util:unescape-uri($uri, "UTF-8")    
            return system:as-user('admin', 'PASSWORD',
            
                try {
                    let $logpath := console:log($path)
                    let $segment := substring-after($path, 'upload/')
                    
                    (: construct absolute file system path :)
                    let $file-path := concat('/media/jharrop/Overflow/eXist-db/webapp/upload/', $segment)
                    
                    let $vv3 := console:log($file-path)
                    let $exists := file:exists($file-path)
                    let $vv2 := console:log($exists)
                    return 
                        if ($exists) then 
                            let $vvA := console:log("in exists")
                            let $contents := file:read($file-path)
                            let $filesColl := concat($config:data-root, '/files')
                            
                            let $info1 := util:log('INFO ', "storing to " || $config:data-root)
                            let $info2 := util:log('INFO ', "name " || substring-after($segment, '/') )


                            let $filename0 := substring-after($segment, '/')
                            let $prefix := substring-before($filename0, '.')
                            let $ext := substring-after($filename0, '.')
                            let $filename := concat($id, "_", $prefix, "-", $attachmentCount, ".", $ext)
                            (: hmm exide didn't warn me that prefix (without $) was wrong, then eXist happily runs it but it doesn't work as expected :)
                            
                            let $logexfn := console:log($filename)
                            
                            (: store contents :)
                            let $stored := xmldb:store($filesColl, $filename, $contents)
                            let $logexstored := console:log("stored " || $stored)

                            return (                            
                            <attachment filename="{$filename}" mediatype="{$file/@mediatype}" timestamp="{datetime:timestamp()}" ></attachment>   )
                                
                        else 
                                <nofile/>
                } catch * {
                    <failed/>
                })
        else 
                <blank></blank>
        
};
