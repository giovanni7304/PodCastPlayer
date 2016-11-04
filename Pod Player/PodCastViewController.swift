//
//  PodCastViewController.swift
//  Pod Player
//
//  Created by Terry Johnson on 10/31/16.
//  Copyright © 2016 Terry Johnson. All rights reserved.
//

import Cocoa

class PodCastViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var podcastsURLTextField: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    
    var podCasts : [Podcasts] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        podcastsURLTextField.stringValue = "http://www.espn.com/espnradio/podcast/feeds/itunes/podCast?id=2406595"
        
        getPodcasts()
    }
    
    func getPodcasts() {
        if let context = (NSApplication.shared().delegate as? AppDelegate)?.managedObjectContext {
            
            let fetchy = Podcasts.fetchRequest() as NSFetchRequest<Podcasts>
            fetchy.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
            
            do {
                podCasts = try context.fetch(fetchy)
                print(podCasts)
            } catch {}
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func podcastExists(rssURL: String) -> Bool {
        if let context = (NSApplication.shared().delegate as? AppDelegate)?.managedObjectContext {
            
            let fetchy = Podcasts.fetchRequest() as NSFetchRequest<Podcasts>
            fetchy.predicate = NSPredicate(format: "rssURL == %@", rssURL)
            
            do {
                let matchingPodcasts = try context.fetch(fetchy)
                
                if matchingPodcasts.count >= 1 {
                    return true
                } else {
                    return false
                }
            } catch {}
        }
        return false
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return podCasts.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.make(withIdentifier: "podcastcell", owner: self) as? NSTableCellView
        
        let podcast = podCasts[row]
        
        if podcast.title != nil {
            cell?.textField?.stringValue = podcast.title!
        } else {
            cell?.textField?.stringValue = "UNKNOWN"
        }
        
        return cell
    }
    
    @IBAction func addPodcastsClicked(_ sender: AnyObject) {
        if let url = URL(string: podcastsURLTextField.stringValue) {
            URLSession.shared.dataTask(with: url) { (data : Data?, response:URLResponse?, error:Error?) in
                if error != nil {
                    print("URLSession: \(error)")
                } else {
                    if data != nil {
                        let parser = Parser()
                        let info = parser.getPodcastMetaData(data: data!)
                        
                        if self.podcastExists(rssURL: self.podcastsURLTextField.stringValue) {
                            
                            if let context = (NSApplication.shared().delegate as? AppDelegate)?.managedObjectContext {
                                
                                let podcast = Podcasts(context: context)
                                
                                podcast.rssURL = self.podcastsURLTextField.stringValue
                                podcast.imageURL = info.imageURL
                                podcast.title = info.title
                                
                                (NSApplication.shared().delegate as? AppDelegate)?.saveAction(nil)
                                
                                self.getPodcasts()
                            }
                        }
                    }
                }
                }.resume()
            podcastsURLTextField.stringValue = ""
        }
    }
}
