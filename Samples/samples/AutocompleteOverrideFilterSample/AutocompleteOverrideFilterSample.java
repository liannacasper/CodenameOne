package com.codename1.samples;


import com.codename1.components.SpanLabel;
import com.codename1.io.ConnectionRequest;
import com.codename1.io.JSONParser;
import static com.codename1.ui.CN.*;
import com.codename1.ui.Display;
import com.codename1.ui.Form;
import com.codename1.ui.Dialog;
import com.codename1.ui.Label;
import com.codename1.ui.plaf.UIManager;
import com.codename1.ui.util.Resources;
import com.codename1.io.Log;
import com.codename1.ui.Toolbar;
import java.io.IOException;
import com.codename1.ui.layouts.BoxLayout;
import com.codename1.io.NetworkEvent;
import com.codename1.io.NetworkManager;
import com.codename1.processing.Result;
import com.codename1.ui.AutoCompleteTextField;
import com.codename1.ui.TextField;
import com.codename1.ui.list.DefaultListModel;
import java.io.ByteArrayInputStream;
import java.io.InputStreamReader;
import java.util.Map;

/**
 * This file was generated by <a href="https://www.codenameone.com/">Codename One</a> for the purpose 
 * of building native mobile applications using Java.
 */
public class AutocompleteOverrideFilterSample {

    private Form current;
    private Resources theme;
    private ConnectionRequest currRequest;

    public void init(Object context) {
        // use two network threads instead of one
        updateNetworkThreadCount(2);

        theme = UIManager.initFirstTheme("/theme");

        // Enable Toolbar on all Forms by default
        Toolbar.setGlobalToolbar(true);

        // Pro only feature
        Log.bindCrashProtection(true);

        addNetworkErrorListener(err -> {
            // prevent the event from propagating
            err.consume();
            if(err.getError() != null) {
                Log.e(err.getError());
            }
            Log.sendLogAsync();
            Dialog.show("Connection Error", "There was a networking error in the connection to " + err.getConnectionRequest().getUrl(), "OK", null);
        });        
    }
    
    public void start() {
        if(current != null){
            current.show();
            return;
        }
         apiKey = new TextField("");
        showForm();
    }

    public void stop() {
        current = getCurrentForm();
        if(current instanceof Dialog) {
            ((Dialog)current).dispose();
            current = getCurrentForm();
        }
    }
    
    public void destroy() {
    }
    
    public void showForm() {
        Form hi = new Form("Auto Complete", new BoxLayout(BoxLayout.Y_AXIS));
  final DefaultListModel<String> options = new DefaultListModel<>();
  AutoCompleteTextField ac = new AutoCompleteTextField(options) {
      @Override
      protected boolean filter(String text) {
          if(text.length() == 0) {
              return false;
          }
          String[] l = searchLocations(text);
          if(l == null || l.length == 0) {
              return false;
          }
  
          options.removeAll();
          for(String s : l) {
              options.addItem(s);
          }
          return true;
      }
  
  };
  ac.setMinimumElementsShownInPopup(5);
  hi.add(ac);
  hi.add(new SpanLabel("This demo requires a valid google API key to be set below "
           + "you can get this key for the webservice (not the native key) by following the instructions here: "
           + "https://developers.google.com/places/web-service/get-api-key"));
  hi.add(apiKey);
  hi.getToolbar().addCommandToRightBar("Get Key", null, e -> Display.getInstance().execute("https://developers.google.com/places/web-service/get-api-key"));
  hi.show();
}

TextField apiKey;

String[] searchLocations(String text) {        
    try {
        if(text.length() > 0) {
            if (currRequest != null) {
                //currRequest.kill();
                
            }
                
            ConnectionRequest r = new ConnectionRequest();
            currRequest = r;
            r.setPost(false);
            r.setUrl("https://maps.googleapis.com/maps/api/place/autocomplete/json");
            r.addArgument("key", apiKey.getText());
            r.addArgument("input", text);
            NetworkManager.getInstance().addToQueueAndWait(r);
            Map<String,Object> result = new JSONParser().parseJSON(new InputStreamReader(new ByteArrayInputStream(r.getResponseData()), "UTF-8"));
            String[] res = Result.fromContent(result).getAsStringArray("//description");
            return res;
        }
    } catch(Exception err) {
        Log.e(err);
    }
    return null;
}

}
