//
//  NewPost.swift
//  Twitter_Post
//
//  Created by Gabor Csontos on 12/18/16.
//  Copyright © 2016 GaborMajorszki. All rights reserved.
//

import Foundation

//This class contains the NewPost to upload for the server
public class NewPost: AnyObject {
    
    //identify currentuser, after loggin in you are able to save and load with Locksmith
    var userId: String!
    //if the location is setted
    var location: String?
    //if the post contains text
    var text: String?
    //image, video, mp3
    var contentId: String?
    
    
    // You can send a date as well, or set the DB for Datestamp @creating a new row
    //var date: Date!
}
