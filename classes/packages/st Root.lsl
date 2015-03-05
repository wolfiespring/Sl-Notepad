key get_url;        // A key to store the request to fetch a webserv URL from the SL webserv system
string myURL;       // My webserv URL

// Release the URL and reset the script
reset(){
    llReleaseURL(get_url);
    llResetScript();
}

default
{
    // URL is bound to the sim, so when you change sim, make sure to reset the application
    on_rez(integer raar){reset();}
    changed(integer change){
        if(change&CHANGED_REGION){
            llSleep(1);
            reset();
        }
    }
    
    state_entry()
    {
        // Reset the prim media
        llClearLinkMedia(LINK_THIS, 4);
        // This fetches a URL basically making the script into a webserver
        get_url = llRequestURL();
    }
    
    http_request(key id, string method, string body){
        // This fetches our URL
        if(id == get_url){
            // Normally you should have a fallback if url request is denied. I didn't add one while I'm testing.
            if(method == URL_REQUEST_GRANTED){
                // Store my URL and initialize the app by loading the script as a website
                myURL = body;
                llSetLinkMedia(LINK_THIS, 4, [
                    PRIM_MEDIA_AUTO_PLAY, TRUE,
                    PRIM_MEDIA_CURRENT_URL, myURL,
                    PRIM_MEDIA_HOME_URL, myURL,
                    PRIM_MEDIA_HEIGHT_PIXELS, 256,
                    PRIM_MEDIA_WIDTH_PIXELS, 256,
                    PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE,
                    PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_OWNER
                ]);
            }
        }else{
            // This is the script webserver
            
            // Path info lets you get the app request.
            // Like if the url was api.secondlife.com/someuuid/edit/1
            // The path list would contain ["edit", "1"]
            list path = llParseString2List(llGetHTTPHeader(id, "x-path-info"), ["/"], []);
            
            // Body is where we store the HTML data
            string body;
            
            // First path string (method) was edit, so we'll load the editor.
            if(llList2String(path,0) == "edit"){
                body = "<div contentEditable=\"true\" style=\"overflow:visible; min-height:50%\">Write your note here</div><input type=\"button\" value=\"Save\" />
<script>
var btn = $('input[type=button]');
btn.click(function(){
    $.get('"+myURL+"/save/0?'+encodeURIComponent($('div').first().html()))
    .done(function(){btn.val('Saved!');}).fail(function(data){btn.val('Fail. Try again.');}).always(function(){setTimeout(function(){btn.val('Save');}, 3000);});
});
</script>";
            }
            
            // Method was save I didn't actually write any saving. But it gives you the text
            else if(llList2String(path,0) == "save"){
                // This is the text that should be saved
                string text = llUnescapeURL(llGetHTTPHeader(id,"x-query-string"));
                llOwnerSay(text);
                llHTTPResponse(id, 200, "SUCCESS");
                return;
            }
            
            // No method, index page
            else{
                body = "This is the default page which lists your sheets. <a href=\""+myURL+"/edit"+"\">Edit</a>";
            }
            
            // Set content type as HTML (for formatting)
            llSetContentType(id, CONTENT_TYPE_HTML);
            
            // Send the HTML data to the prim media
            llHTTPResponse(id, 200, "<html><head> <script src=\"https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js\"></script><style type=\"text/css\">body{background:#FAF;}</style></head><body>"+body+"</body></html>");
        }
    }
}
