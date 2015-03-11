key get_url;        // A key to store the request to fetch a webserv URL from the SL webserv system
string myURL;       // My webserv URL

// Release the URL and reset the script
reset(){
    llReleaseURL(get_url);
    llResetScript();
}

#define urldecode(input) llUnescapeURL(str_replace("+", " ", input))

ajaxCallback(key request, integer success, list data, list messages){
	llHTTPResponse(request, 200, llList2Json(JSON_ARRAY, [success, llList2Json(JSON_OBJECT, data), mkarr(messages)]));
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
                    //PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_NONE,
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
            string headOut;
			string withHeader;
			
			
			
	// AJAX		
			if(llList2String(path,0) == "save"){
                // This is the text that should be saved
				_saveSharedScript(jVal(body, [0]), ["t"], jVal(body,[1]));
				_saveSharedScript(jVal(body, [0]), ["e"], (string)llGetUnixTime());
				
                ajaxCallback(id, TRUE, [], []);
                return;
            }
			
			else if(llList2String(path,0) == "del"){
				string del = urldecode(llList2String(path,1));
				_saveSharedScript(del, [], "");
				ajaxCallback(id, TRUE, ["n", del], []);
			}
			
			
	// WEBPAGES
			
			
			// EDITOR
            // First path string (method) was edit, so we'll load the editor.
            else if(llList2String(path,0) == "edit"){
				string header = llList2String(path,1);
				string txt = "Write your note here.";
				if(llGetListLength(path)<2)header = llGetSubString(body, 5, -1);
				header = urldecode(header);
				if(llGetListLength(path)>1)txt = _shared(header, ["t"]);
				withHeader = "withHeader";
				headOut += "Diary.editPage = '"+header+"';";
				bodyOut += "<div class=\"header\"><div class=\"rightheader\"><input type=\"button\" value=\"Save\" />
<input type=\"button\" value=\"Back\" data-href=\""+myURL+"\" />
</div><p>"+header+"</p><div class=\"clear\"></div></div>";
				bodyOut += "<div class=\"editable\" contentEditable=\"true\" style=\"min-height:50%\">"+txt+"</div>";
            }
			
			// INDEX
            // No method, index page
            else{
				string indexes = (string)llGetLinkMedia(_SHARED_CACHE_ROOT, 0, [PRIM_MEDIA_HOME_URL, PRIM_MEDIA_CURRENT_URL]);
				list names = llDeleteSubList(llJson2List(llJsonGetValue(indexes, [SharedVarsVar$scriptName])),0,0);
				
                bodyOut += "
<div class=\"header\">
<form method=\"POST\" id=\"insertNewNote\" action=\""+myURL+"/edit"+"\">
<input type=\"submit\" class=\"rightheader\" value=\"Add Note\" />
<input type=\"text\" placeholder=\"Name\" name=\"name\" />
</form>
<div class=\"clear\"></div>
</div>";
				bodyOut+="<div class=\"buttons\"></div>";
				headOut+="Diary.buttons = "+mkarr(names)+";";
				withHeader = "withHeader";
            }
            
            // Set content type as HTML (for formatting)
            llSetContentType(id, CONTENT_TYPE_HTML);
            
            // Send the HTML data to the prim media
			string out = "<html><head><script>function Diary(){}"+headOut+" Diary.URL='"+myURL+"';</script><script src=\"http://panda.place/usr/wolfie/lsl/diary/js.js\"></script></head><body><div class=\"wrapper "+withHeader+"\"><div id=\"debug\" class=\"hidden\"></div>"+bodyOut+"</div></body></html>";
            //llOwnerSay(out);
			llHTTPResponse(id, 200, out);
        }
    }
}
