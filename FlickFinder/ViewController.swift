//
//  ViewController.swift
//  FlickFinder
//
//  Created by Sanjay Noronha on 2015/12/27.
//  Copyright © 2015 funza Academy. All rights reserved.
//

import UIKit

/* Pending
// A. Remove Autolayout warnings
// B. Label size increase
// C. Appropriate Search Icon ( 200 X 200)
// D. Implementing max pages + images per page in a random way
*/



let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "bf5b229570f2bd56e80e0240bd687cc4"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"




class ViewController: UIViewController, UITextFieldDelegate {
    
    
    // MARK: Properties
    
    @IBOutlet var searchText: UITextField!
    @IBOutlet var lonText: UITextField!
    @IBOutlet var latText: UITextField!
    
    @IBOutlet var myImageView: UIImageView!
    
    @IBOutlet var myLabel: UILabel!
    
    @IBOutlet var geoButton: UIButton!
    @IBOutlet var textButton: UIButton!
    
    let notifCenter = NSNotificationCenter.defaultCenter()
    let replacementStr = "+" //specfic to FLick API
    
    var kybrdSwitch:Bool = true //used in determining when to move frame (up or down)
    
    
    enum SearchType{
        
        case Textual, Coordinate
    }
    
    
    // MARK: Actions
    @IBAction func performSearch(sender: UIButton)
    {
        
        if sender == textButton {
            
            //continue only if validations are successful
            if performValidations(SearchType.Textual,sender: sender) {
                getImageFromFlickr(SearchType.Textual)
                
            }
        }
        else {
            
            if performValidations(SearchType.Coordinate,sender: sender) {
                getImageFromFlickr(SearchType.Coordinate)
            }
            
        }
        
    }
    
    
    
    //MARK: Delegate functions
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        if textField == searchText
        {
            // clear coordinate fields + label and disable button
            lonText.text = ""
            latText.text = ""
            myLabel.text = ""
            
            textButton.enabled = true
            geoButton.enabled = false
            
        }
        
        if textField == latText || textField == lonText
        {
            // clear text search field + label and disable button
            searchText.text = ""
            myLabel.text = ""
            
            geoButton.enabled = true
            textButton.enabled = false
        }
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        //disable Key Pad (textual)
        textField.resignFirstResponder()
        
        return true
    }
    
    
    // MARK: Override functions
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        super.touchesBegan(touches, withEvent: event)
        
        view.endEditing(true)
        
        
        
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // add Delegates
        searchText.delegate = self
        latText.delegate = self
        lonText.delegate = self
        
        // add Observers
        notifCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        notifCenter.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        // Nav Bar background color
        self.view.backgroundColor = UIColor(red: 221/255, green: 236/255, blue: 239/255, alpha: 1.0)
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
       
        // remove Observers
        notifCenter.removeObserver(self)
        
    }
    
    
    // MARK: Generic functions
    
    func performValidations(mySearchType:SearchType,sender:UIButton) -> Bool
    {
        
        /*
        * Generic
        */
        if  searchText.text?.characters.count == 0 && ( latText.text?.characters.count == 0 || lonText.text?.characters.count == 0 )
        {
            if sender == textButton {
                
                myLabel.text = " Search text cannot be blank. Please entry values and try again."
                return false
                
            }
            else {
                myLabel.text = " Latitude and Longitude values must be entered. Please try again."
                return false
            }
        }
        
        /*
        * Coordinate specific
        */
        if mySearchType == SearchType.Coordinate
        {
            
            //pretty sure that both text fields have values
            let latValue = Double(latText.text!)
            let lonValue = Double(lonText.text!)
            
            
            
            if latValue < -90 || latValue > 90
            {
                
                myLabel.text = " Latitude must be between -90 and 90. Please try again."
                return false
                
            }
            
            if lonValue < -180 || lonValue > 180
            {
                
                myLabel.text = " Longitude must be between -180 and 180. Please try again."
                return false
                
            }
            
        }
        
        return true
        
    }
    
    func getImageFromFlickr(mySearchType:SearchType) {
        
        /* 2 - API method main arguments */
        var methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        
        /* 3 - Text Search Specific Values */
        if mySearchType == SearchType.Textual
        {
            methodArguments["text"] = searchText.text!.stringByReplacingOccurrencesOfString(" ", withString: replacementStr)
            
        } /* 4 - Coordinate Specific Values */
        else if mySearchType == SearchType.Coordinate
        {
            
            methodArguments["lat"] = latText.text!
            methodArguments["lon"] = lonText.text!
            
        }
        
        
        /* 5 - Initialize session and url */
        let session = NSURLSession.sharedSession()
        
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        /* 6 - Initialize task for getting data */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* Unlike an if statement, guard statements only run if the conditions are not met */
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                self.myLabel.text = "There was an error with your request: \(error)"
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    self.myLabel.text = "Your request returned an invalid response! Status code: \(response.statusCode)!"
                } else if let response = response {
                    self.myLabel.text = "Your request returned an invalid response! Response: \(response)!"
                } else {
                    self.myLabel.text  = "Your request returned an invalid response!"
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                self.myLabel.text = "No data was returned by the request!"
                return
            }
            
            /* 6 - Parse the data (i.e. convert the data to JSON and look for values!) */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                
               // print(parsedResult)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Are the "photos" and "photo" keys in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary,
                photoArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find keys 'photos' and 'photo' in \(parsedResult)")
                    return
            }
            
            /* Ok, do we have any photos? */
            if photoArray.count == 0 {
                self.myLabel.text = "No images found for search. Please try again."
                return
            }
            
            
            /* 7 - Generate a random number, then select a random photo */
            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
            
            
            let photoDictionary = photoArray[randomPhotoIndex] as [String: AnyObject]
            
            
            /* GUARD: Does our photo have a key for 'url_m'? */
            guard let imageUrlString = photoDictionary["url_m"] as? String else {
                print("Cannot find key 'url_m' in \(photoDictionary)")
                return
            }
            
            guard let imageTitle = photoDictionary["title"] as? String else {
                print("Cannot find key 'title' in \(photoDictionary)")
                return
            }
            
            
            
            /* 8 - If an image exists at the url, set the image and title */
            let imageURL = NSURL(string: imageUrlString)
            if let imageData = NSData(contentsOfURL: imageURL!) {
                dispatch_async(dispatch_get_main_queue(), {
                   // Keep updates minimal
                    self.myImageView.image = UIImage(data: imageData)
                    self.myLabel.text = imageTitle ?? "(Untitled)"
                })
            } else {
                print("Image does not exist at \(imageURL)")
            }
        }
        
        /* 9 - Resume (execute) the task */
        task.resume()
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + ("&").join(urlVars)
    }
    
    
    
    // MARK: Observer functions
    
    func keyboardWillShow(notification: NSNotification)
    {
        
        //get height of the keyboard : h
        let info:NSDictionary = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        let keyboardHeight: CGFloat = keyboardSize.height
        
        //move the main view up by: h
        if ( latText.editing || lonText.editing || searchText.editing ) && ( kybrdSwitch == true )
        {
            self.view.frame.origin.y = self.view.frame.origin.y - keyboardHeight
            kybrdSwitch = false
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification)
    {
        
        //get height of the keyboard : h
        let info:NSDictionary = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        let keyboardHeight: CGFloat = keyboardSize.height
        
        //move the main view up by: h
        
        if ( latText.editing || lonText.editing || searchText.editing ) && ( kybrdSwitch == false )
            
        {
            self.view.frame.origin.y = self.view.frame.origin.y + keyboardHeight
            kybrdSwitch = true
        }
        
    }
    
}



