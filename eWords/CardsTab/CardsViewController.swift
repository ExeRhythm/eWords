//
//  CardsViewController.swift
//  eWords2
//
//  Created by Matthew on 20.02.2020.
//  Copyright © 2020 iMac Matthew. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftMessages
import GoogleMobileAds
class CardsViewController: UIViewController {
    var timer = Timer()
    var wordOnCard:Word?
    let synth = AVSpeechSynthesizer()
    var isFlipped = false
    var selectedCollection = "All words"
    var isAutoPlayEnabled = false
    var areLabelsReversed: Bool {
        get {
            return GeneralData.sharedInstance.areLabelsReversed
        }
        set(newValue) {
            GeneralData.sharedInstance.areLabelsReversed = newValue
        }
    }
    var words:[Word]?
    @IBOutlet weak var autoPlayButton: UIButton!
    @IBAction func starPressed(_ sender: UIButton) {
        if words?.count ?? 0 != 0 {
            let word = wordOnCard!
            let results = GeneralData.sharedInstance.favoriteWords?.filter({ (favoriteWord) -> Bool in
                return favoriteWord.foreignWord == word.foreignWord && favoriteWord.nativeWord == word.nativeWord
            })
            if results?.count ?? 0 > 0 {
                GeneralData.sharedInstance.favoriteWords = GeneralData.sharedInstance.favoriteWords?.filter({ (favoriteWord) -> Bool in
                    return favoriteWord.foreignWord != word.foreignWord && favoriteWord.nativeWord != word.nativeWord
                })
            } else {
                if GeneralData.sharedInstance.favoriteWords != nil {
                    GeneralData.sharedInstance.favoriteWords?.append(word)
                } else {
                    GeneralData.sharedInstance.favoriteWords = [word]
                }
            }
            if word.isFavorite {
                sender.setImage(UIImage(named: "starFilled"), for: [])
            } else {
                sender.setImage(UIImage(named: "starEmpty"), for: [])
            }
        } else {
            warnUser(title: "No words added!", messagge: "Please add a new word in \"My words\" or tap on a button \"Change collection\"")
        }
    }
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var star: UIButton!
    @IBOutlet weak var collectionNameLabel: UILabel!
    @IBOutlet weak var worldLabel: UILabel!
    @IBOutlet weak var cardView: UIView!
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        if wordOnCard == nil {
            warnUser(title: "No words added!", messagge: "Please add a new word in \"My words\" or tap on a button \"Change collection\"")
            return
        }
        if !isAutoPlayEnabled {
            nextWord()
        }
    }
    @IBAction func speakWordButtonPressed(_ sender: UIButton) {
        if wordOnCard == nil {
            warnUser(title: "No words added!", messagge: "Please add a new word in \"My words\" or tap on a button \"Change collection\"")
            return
        }
        if !isAutoPlayEnabled {
            let utterance = AVSpeechUtterance(string: wordOnCard?.foreignWord ?? "")
            synth.stopSpeaking(at: AVSpeechBoundary.immediate)
            utterance.voice = AVSpeechSynthesisVoice(language: GeneralData.sharedInstance.foreignLanguageCode ?? "en-US")
            synth.speak(utterance)
        }
    }
    
    @IBAction func autoPlayButtonPressed(_ sender: UIButton) {
        if wordOnCard == nil {
            warnUser(title: "No words added!", messagge: "Please add a new word in \"My words\" or tap on a button \"Change collection\"")
            return
        }
        isAutoPlayEnabled.toggle()
        if isAutoPlayEnabled {
            UIApplication.shared.isIdleTimerDisabled = true
            nextWord()
            sender.setImage(UIImage(named: "pause-button"), for: [])
            speakWord(onForeignLanguage: !areLabelsReversed)
        } else {
            sender.setImage(UIImage(named: "play-button"), for: [])
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    @IBAction func reverseButtonTapped(_ sender: UIBarButtonItem) {
        reverseLabels()
        nextWord()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if words == nil {
            words = GeneralData.sharedInstance.userWords
        }
        nextWord()
        bannerView.adUnitID = "ca-app-pub-6804648379784599/8889298488"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        cardView.clipsToBounds = true
        cardView.layer.cornerRadius = 15
        cardView.layer.borderColor = UIColor.black.cgColor
        cardView.layer.borderWidth = 2
        synth.delegate = self
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.flipCard))
        cardView.addGestureRecognizer(gesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if selectedCollection == "My words" {
            words = GeneralData.sharedInstance.userWords
        } else  if selectedCollection == "Favorites" {
            words = GeneralData.sharedInstance.favoriteWords
        } else  if selectedCollection == "All words" {
            words = getAllWords()
        }
        collectionNameLabel.text = "Collection: \(selectedCollection)"
        if worldLabel.text == "No words added..." {
            nextWord()
        }
        if wordOnCard?.isFavorite ?? false {
            star.setImage(UIImage(named: "starFilled"), for: [])
        } else {
            star.setImage(UIImage(named: "starEmpty"), for: [])
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isAutoPlayEnabled = false
        synth.stopSpeaking(at: .immediate)
        autoPlayButton.setImage(UIImage(named: "play-button"), for: [])
        UIApplication.shared.isIdleTimerDisabled = false
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! ChangeCollectionTableViewController
        destination.cardsViewController = self
    }
    func speakWord(onForeignLanguage:Bool) {
        var utterance:AVSpeechUtterance!
        if onForeignLanguage {
            utterance = AVSpeechUtterance(string: wordOnCard?.foreignWord ?? "")
            utterance.voice = AVSpeechSynthesisVoice(language: GeneralData.sharedInstance.foreignLanguageCode ?? "en-US")
        } else {
            utterance = AVSpeechUtterance(string: wordOnCard?.nativeWord ?? "")
            utterance.voice = AVSpeechSynthesisVoice(language: GeneralData.sharedInstance.nativeLanguageCode ?? "ru-RU")
        }
        synth.stopSpeaking(at: AVSpeechBoundary.immediate)
        synth.speak(utterance)
    }
    func reverseLabels() {
        areLabelsReversed = !(areLabelsReversed)
    }
    func warnUser(title: String, messagge: String) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        var config = SwiftMessages.Config()
        config.presentationStyle = .bottom
        
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.warning)
        view.configureDropShadow()
        view.button?.backgroundColor = .clear
        view.button?.setTitle("", for: [])
//        view.configureContent(title: "No words added!", body: "Please add a new word in \"My words\" or tap on a button \"Change collection\"")
        view.configureContent(title: title, body: messagge)

        view.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 10
        SwiftMessages.show(config:config, view: view)
    }
    func nextWord() {
        isFlipped = false
        if words?.count != 0, words != nil {
            let randomNumber = Int.random(in: 0...words!.count - 1)
            wordOnCard = words![randomNumber]
            if areLabelsReversed  {
                worldLabel.text = wordOnCard?.nativeWord
            } else {
                worldLabel.text = wordOnCard?.foreignWord
            }
        } else {
            worldLabel.text = "No words added..."
            isAutoPlayEnabled = false
        }
        if wordOnCard?.isFavorite ?? false {
            star.setImage(UIImage(named: "starFilled"), for: [])
        } else {
            star.setImage(UIImage(named: "starEmpty"), for: [])
        }
    }
    
    @objc func flipCard() {
        if wordOnCard == nil {
            warnUser(title: "No words added!", messagge: "Please add a new word in \"My words\" or tap on a button \"Change collection\"")
            return
        }
        let transitionOptions: UIView.AnimationOptions = [.transitionFlipFromRight, .showHideTransitionViews]
        UIView.transition(with: cardView, duration: 0.75, options: transitionOptions, animations: {
            self.cardView.isHidden = true
        })
        isFlipped = !isFlipped
        if isFlipped {
            if areLabelsReversed  {
                worldLabel.text = wordOnCard?.foreignWord
            } else {
                worldLabel.text = wordOnCard?.nativeWord
            }
            
        } else {
            if areLabelsReversed  {
                worldLabel.text = wordOnCard?.nativeWord
            } else {
                worldLabel.text = wordOnCard?.foreignWord
            }
        }
        
        UIView.transition(with: cardView, duration: 0.75, options: transitionOptions, animations: {
            self.cardView.isHidden = false
        })
    }
    func getAllWords() -> [Word] {
        let userWords = GeneralData.sharedInstance.userWords ?? []
        let boughtCollections = GeneralData.sharedInstance.boughtCollections
        var allWords: [Word] = []
        let collectionsData = GeneralData.sharedInstance.collectionsData
        for (nameOfCollection, collection) in collectionsData {
            if boughtCollections.contains(nameOfCollection) {
                let smallCollectionData = GeneralData.sharedInstance.makeCollectionDataSmaller(collection: collection)
                for word in smallCollectionData {
                    allWords.append(word)
                }
            }
        }
        for userWord in userWords {
            allWords.append(userWord)
        }
        return allWords
    }
    
}

extension CardsViewController: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if isAutoPlayEnabled {
            if !self.isFlipped {
                DispatchQueue.main.asyncAfter(deadline: .now() + GeneralData.sharedInstance.cardsTempo) {
                    self.flipCard()
                    self.speakWord(onForeignLanguage: self.areLabelsReversed)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if self.isAutoPlayEnabled {
                        self.nextWord()
                        self.speakWord(onForeignLanguage: !self.areLabelsReversed)
                    }
                }
            }
            
        }
    }
}
