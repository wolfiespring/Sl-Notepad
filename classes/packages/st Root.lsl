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
		initShared();
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
            string bodyOut;
            
            // First path string (method) was edit, so we'll load the editor.
            if(llList2String(path,0) == "edit"){
				string header = llList2String(path,1);
				string txt = "Write your note here.";
				if(llGetListLength(path)<2)header = llGetSubString(body, 5, -1);
				header = llUnescapeURL(str_replace("+", " ", header));
				if(llGetListLength(path)>1)txt = _shared(header, ["t"]);
				
                bodyOut = "<h1><span id=\"n\">"+header+"</span> <a href=\""+myURL+"\">Back</a></h1><div contentEditable=\"true\" style=\"overflow:visible; min-height:50%\">"+txt+"</div><input type=\"button\" value=\"Save\" />
<script>
var btn = $('input[type=button]');
btn.click(function(){
    $.post('"+myURL+"/save', JSON.stringify([$('#n').html(), $('div:first').html()]))
    .done(function(){btn.val('Saved!');}).fail(function(data){btn.val('Fail. Try again.');}).always(function(){setTimeout(function(){btn.val('Save');}, 3000);});
});
</script>";
            }
            
            // Method was save I didn't actually write any saving. But it gives you the text
            else if(llList2String(path,0) == "save"){
                // This is the text that should be saved
				_saveSharedScript(jVal(body, [0]), ["t"], jVal(body,[1]));
                llHTTPResponse(id, 200, "SUCCESS");
                return;
            }
            
            // No method, index page
            else{
				string indexes = (string)llGetLinkMedia(_SHARED_CACHE_ROOT, 0, [PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL]);
				list names = llDeleteSubList(llJson2List(llJsonGetValue(indexes, [SharedVarsVar$scriptName])),0,0);
				
				bodyOut+="<ul>";
				list_shift_each(names, n, {
					bodyOut+="<li><a href=\""+myURL+"/edit/"+llEscapeURL(n)+"\">"+n+"</a></li>";
				})
				bodyOut+="</ul>";
				
                bodyOut += "<form method=\"POST\" action=\""+myURL+"/edit"+"\">
<input type=\"text\" placeholder=\"Name\" name=\"name\" />
<input type=\"submit\" value=\"Add New Note\" />
</form>";
            }
            
            // Set content type as HTML (for formatting)
            llSetContentType(id, CONTENT_TYPE_HTML);
            
            // Send the HTML data to the prim media
            llHTTPResponse(id, 200, "<html><head> <script src=\"https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js\"></script><style type=\"text/css\">body{background:#FAF;}h1{font-size:18px;}</style></head><body>"+bodyOut+"</body></html>");
        }
    }
}
