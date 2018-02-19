xquery version "3.0";

(: 
 : Defines all the RestXQ endpoints used by the XForms.
 :)
module namespace issues="http://plutext.org/eXist/xrxTracker";

import module namespace config="http://plutext.org/eXist/xrxTracker/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace sm="http://exist-db.org/xquery/securitymanager";
import module namespace datetime="http://exist-db.org/xquery/datetime";
import module namespace f="http://plutext.org/eXist/xrxTracker/file" at "mvfile.xqm";
(:  import module namespace fn= "http://www.functx.com" at "functx.xqm"; :)

declare namespace rest="http://exquery.org/ns/restxq";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:indent "yes";

(:  declare variable $issues:data := $config:app-root || "/data/issues"; :)
declare variable $issues:data := "/db/apps/xrxTracker/data/issues"; 

(:   console:log("Hello world!") :)

(:~
 : List all issues and return them as XML.
 :)
declare
    %rest:GET
    %rest:path("/issue")
    %rest:produces("application/xml", "text/xml")
function issues:issues() {
     console:log("issues"),
    <issues>
    {
        (: for $issue in collection($config:app-root || "/data/issues")/issue :)
        let $log := util:log("INFO", "\nissues invokved\n ")
        for $issue in collection("/db/apps/xrxTracker/data/issues")/issue 
        return
            $issue
    }
    </issues> 
};

(:~
 : Test: list all issuees in JSON format. For this function to be chosen,
 : the client should send an Accept header containing application/json.
 :)
(:declare:)
(:    %rest:GET:)
(:    %rest:path("/issue"):)
(:    %rest:produces("application/json"):)
(:    %output:media-type("application/json"):)
(:    %output:method("json"):)
(:function issues:issuees-json() {:)
(:    issues:issuees():)
(:};:)

(:~
 : Retrieve an issue identified by id.
 :)
declare 
    %rest:GET
    %rest:path("/issue/{$id}")
function issues:get-issue($id as xs:string*) {
    collection($issues:data)/issue[@id = $id]
};

(:~
 : Search issues using a given field and a (lucene) query string.
 :)
declare 
    %rest:GET
    %rest:path("/search")
    %rest:form-param("query", "{$query}", "")
    %rest:form-param("field", "{$field}", "title")
function issues:search-issues($query as xs:string*, $field as xs:string*) {
    <issues>
    {
        if ($query != "") then
            switch ($field)
                case "title" return
                    collection($issues:data)/issue[ngram:contains(title, $query)]
                case "summary" return
                    collection($issues:data)/issue[ngram:contains(summary, $query)]
                case "resolution" return
                    collection($issues:data)/issue[ngram:contains(resolution, $query)]
                default return
                    collection($issues:data)/issue[ngram:contains(., $query)]
        else
            collection($issues:data)/issue
    }
    </issues> 
};

(:~
 : Update an existing issue or store a new one. The issue XML is read
 : from the request body.
 :)
declare
    %rest:PUT("{$content}")
    %rest:path("/issue")
function issues:create-or-edit-issue($content as node()*) {
       console:log("put"),
    let $id := count(collection("/db/apps/xrxTracker/data/issues")/issue)+1
  (: let $id := ($content/issue/@id, util:uuid())[1] :)
  (: copy the attributes otherwise lost below :)
  let $assignee := $content/issue/@assignee
  let $component := $content/issue/@component
  let $priority := $content/issue/@priority
  let $milestone := $content/issue/@milestone
  let $status := $content/issue/@status
  let $type := $content/issue/@type
  let $author := sm:id()/sm:id/sm:real/sm:username
  
  (: TODO: timestamp etc if more than 1 comment was added :)
  let $lastComment :=
        if ($content/issue/comments/comment[last()]/@isNew) then
            <comment author="{$author}" timestamp="{datetime:timestamp()}" 
                    milestone="{$milestone}" priority="{$priority}" status="{$status}" 
                    type="{$type}">{$content/issue/comments/comment[last()]/text()}</comment>
        else 
            $content/issue/comments/comment[last()]
            
  (: if there are no comments, create first comment from summary :)
  let $comments :=
        if ( $content/issue[@id='NEW']) then
            <comments>
                <comment author="{$author}" timestamp="{datetime:timestamp()}" priority="{$priority}" status="{$status}" type="{$type}">{$content/issue/summary/text()}</comment>
                <!-- FIXME
                {$content/issue/comments/comment[position()<last()]} -->
                {$lastComment}
                <placeholder>placeholder</placeholder>
            </comments> 
        else 
            <comments>
                {$content/issue/comments/comment[position()<last()]}
                {$lastComment}
                <placeholder>placeholder</placeholder>
            </comments> 
  
                    
    let $newAttachment := f:node-to-db($content/issue/files/file, $id, string(count($content/issue/attachments/*)+1) ) 

    
    let $data :=
        <issue id="{$id}" assignee="{$assignee}" component="{$component}" milestone="{$milestone}" priority="{$priority}" status="{$status}" type="{$type}">
            { $content/issue/node()[not(local-name()='comments') 
                    and not (local-name()='attachments')
                    and not (local-name()='files')] }
            { $comments }
            <attachments>
                { $content/issue/attachments/node() }
                { $newAttachment[local-name()='attachment'] }
            </attachments>
            <files>
                <file filename="" mediatype="" size=""/>
            </files>   
        </issue>
        (: how to indent / pretty-print that?? :)
        
    let $log := util:log("DEBUG", "Storing data into " || $issues:data)
    let $stored := xmldb:store($issues:data, $id || ".xml", $data)
    
    
            
    return
        issues:issues()
};

(:~
 : Delete an issue identified by its uuid.
 
declare
    %rest:DELETE
    %rest:path("/issue/{$id}")
function issues:delete-issue($id as xs:string*) {
    xmldb:remove($issues:data, $id || ".xml"),
    issues:issues()
};  :)