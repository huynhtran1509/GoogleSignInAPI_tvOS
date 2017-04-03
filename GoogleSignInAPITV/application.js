//# sourceURL=application.js

/*
 application.js
 GoogleSignInAPITV
 
 Copyright (c) 2017 WillowTree Apps. All rights reserved.
*/

/*
 * This file provides an example skeletal stub for the server-side implementation 
 * of a TVML application.
 *
 * A javascript file such as this should be provided at the tvBootURL that is 
 * configured in the AppDelegate of the TVML application. Note that  the various 
 * javascript functions here are referenced by name in the AppDelegate. This skeletal 
 * implementation shows the basic entry points that you will want to handle 
 * application lifecycle events.
 */

/**
 * @description The onLaunch callback is invoked after the application JavaScript 
 * has been parsed into a JavaScript context. The handler is passed an object 
 * that contains options passed in for launch. These options are defined in the
 * swift or objective-c client code. Options can be used to communicate to
 * your JavaScript code that data and as well as state information, like if the 
 * the app is being launched in the background.
 *
 * The location attribute is automatically added to the object and represents 
 * the URL that was used to retrieve the application JavaScript.
 */
App.onLaunch = function(options) {
    /*
    var alert = createAlert("Hello World!", "Welcome to tvOS");
    navigationDocument.pushDocument(alert);
     */
    var loginPage = createGoogleLogin();
    navigationDocument.pushDocument(loginPage);
}


App.onWillResignActive = function() {

}

App.onDidEnterBackground = function() {

}

App.onWillEnterForeground = function() {
    
}

App.onDidBecomeActive = function() {
    
}

App.onWillTerminate = function() {
    
}

var createGoogleLogin = function() {
    var loginDiv = `<divTemplate>
    <img id="profileImage" style="tv-align:center; width:200; height:200; margin:50;" src="" />
    <button id="shareLinkButton" style="tv-align:center; width:573; height:108; margin:20;">
    <text style="font-size:39" >Sign in with Google</text>
    </button>
    </divTemplate>
`
    var parser = new DOMParser();
    var loginDoc = parser.parseFromString(createGoogleLogin, "application/xml");
    return loginDoc;
}


/**
 * This convenience funnction returns an alert template, which can be used to present errors to the user.
 */
var createAlert = function(title, description) {

    var alertString = `<?xml version="1.0" encoding="UTF-8" ?>
        <document>
          <alertTemplate>
            <title>${title}</title>
            <description>${description}</description>
          </alertTemplate>
        </document>`

    var parser = new DOMParser();

    var alertDoc = parser.parseFromString(alertString, "application/xml");

    return alertDoc
}
