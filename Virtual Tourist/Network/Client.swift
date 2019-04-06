//
//  Client.swift
//  Virtual Tourist
//
//  Created by Mario Cezzare on 05/04/19.
//  Copyright © 2019 Mario Cezzare. All rights reserved.
//


import UIKit

class Client {
    
    // MARK: - Properties
    
    var session = URLSession.shared
    private var tasks: [String: URLSessionDataTask] = [:]
    
    // MARK: - Shared Instance
    
    class func shared() -> Client {
        struct Singleton {
            static var shared = Client()
        }
        return Singleton.shared
    }
    
    /// Make a search on Flickr API using a GET Request
    ///
    /// - Parameters:
    ///   - latitude: latitude coordinate
    ///   - longitude: longitude coordinate
    ///   - totalPages: number of pages
    ///   - completion: closure for completion task
    func searchFlickrImages(latitude: Double, longitude: Double, totalPages: Int?, completion: @escaping (_ result: PhotosFlickr?, _ error: Error?) -> Void) {
        
        // choosing a random page.
        var page: Int {
            if let totalPages = totalPages {
                let page = min(totalPages, 4000/FlickrParameterValues.PhotosPerPage)
                return Int(arc4random_uniform(UInt32(page)) + 1)
            }
            return 1
        }
        let bbox = bboxString(latitude: latitude, longitude: longitude)
        
        let parameters = [
            FlickrParameterKeys.Method           : FlickrParameterValues.SearchMethod
            , FlickrParameterKeys.APIKey         : FlickrParameterValues.APIKey
            , FlickrParameterKeys.Format         : FlickrParameterValues.ResponseFormat
            , FlickrParameterKeys.Extras         : FlickrParameterValues.MediumURL
            , FlickrParameterKeys.NoJSONCallback : FlickrParameterValues.DisableJSONCallback
            , FlickrParameterKeys.SafeSearch     : FlickrParameterValues.UseSafeSearch
            , FlickrParameterKeys.BoundingBox    : bbox
            , FlickrParameterKeys.PhotosPerPage  : "\(FlickrParameterValues.PhotosPerPage)"
            , FlickrParameterKeys.Page           : "\(page)"
        ]
        
        _ = taskForGETMethod(parameters: parameters) { (data, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let data = data else {
                let userInfo = [NSLocalizedDescriptionKey : "Could not retrieve data."]
                completion(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
                return
            }
            
            do {
                let photosParser = try JSONDecoder().decode(PhotosFlickr.self, from: data)
                completion(photosParser, nil)
            } catch {
                print("\(#function) error: \(error)")
                completion(nil, error)
            }
        }
    }
    
    
    /// Download the image
    ///
    /// - Parameters:
    ///   - imageUrl: a string with the image URL
    ///   - result: closure to process the data or error
    func downloadImage(imageUrl: String, result: @escaping (_ result: Data?, _ error: NSError?) -> Void) {
        guard let url = URL(string: imageUrl) else {
            return
        }
        let task = taskForGETMethod(nil, url, parameters: [:]) { (data, error) in
            result(data, error)
            self.tasks.removeValue(forKey: imageUrl)
        }
        
        if tasks[imageUrl] == nil {
            tasks[imageUrl] = task
        }
    }
    
    
    /// Abort the task of download
    ///
    /// - Parameter imageUrl: a string with the image URL
    func cancelDownload(_ imageUrl: String) {
        tasks[imageUrl]?.cancel()
        if tasks.removeValue(forKey: imageUrl) != nil {
            print("\(#function) task canceled: \(imageUrl)")
        }
    }
    
}

extension Client {
    
    // MARK: - GET
    
    
    /// Simplified method for make HTTP GET Requests
    ///
    /// - Parameters:
    ///   - method: GET
    ///   - customUrl: a valid URL for make the request
    ///   - parameters: array of parameters to use on QueryString
    ///   - completionHandlerForGET: closure to completionHandlerForGET
    /// - Returns: a URLSessionDataTask
    func taskForGETMethod(
        _ method               : String? = nil,
        _ customUrl            : URL? = nil,
        parameters             : [String: String],
        completionHandlerForGET: @escaping (_ result: Data?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        /* 1/2/3. Build the URL, Configure the request */
        let request: NSMutableURLRequest!
        if let customUrl = customUrl {
            request = NSMutableURLRequest(url: customUrl)
        } else {
            request = NSMutableURLRequest(url: buildURLFromParameters(parameters, withPathExtension: method))
        }
        
        showActivityIndicator(true)
        
        /* 4. Make the request */
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                self.showActivityIndicator(false)
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            if let error = error {
                
                // the request got canceled
                if (error as NSError).code == URLError.cancelled.rawValue {
                    completionHandlerForGET(nil, nil)
                } else {
                    sendError("There was an error with your request: \(error.localizedDescription)")
                }
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            self.showActivityIndicator(false)
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            completionHandlerForGET(data, nil)
            
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    // MARK: - Helpers
    
    /// Create a URL from parameters
    ///
    /// - Parameters:
    ///   - parameters: main method of rest api and any additional parameters to use on QueryString
    ///   - withPathExtension: params of QueryString
    /// - Returns: a ready to use and valid URL
    private func buildURLFromParameters(_ parameters: [String: String], withPathExtension: String? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = Flickr.APIScheme
        components.host = Flickr.APIHost
        components.path = Flickr.APIPath + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: value)
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    
    /// Ensure bbox is bounded by minimum and maximums
    ///
    /// - Parameters:
    ///   - latitude: latitude coordinate
    ///   - longitude: longitude coordinate
    /// - Returns: a string with safe params to use on Flickr API
    private func bboxString(latitude: Double, longitude: Double) -> String {
        //
        let minimumLon = max(longitude - Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.0)
        let minimumLat = max(latitude  - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
        let maximumLat = min(latitude  + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    /// Show or Hide Network activity indicator.
    ///
    /// - Parameter show: use either **true** to show or **false** to hide it
    private func showActivityIndicator(_ show: Bool) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = show
        }
    }
}
