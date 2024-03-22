//
//  GameViewController.swift
//  NumberMemoryGame
//
//  Created by 村中令 on 2022/09/14.
//

import UIKit
import AVFoundation
import GoogleMobileAds

class GameViewController: UIViewController {
    private var yamanoteLineGame: YamanoteLineGame
    @IBOutlet weak var answerTimerProgressView: UIProgressView!
    @IBOutlet weak private var quizTextLabel: UILabel!
    @IBOutlet weak private var answerPieckerView: UIPickerView!

    @IBOutlet weak private var answerButton: UIButton!
    private var yamanoteLineAllShuffled:[YamanoteLine]

    private var selectedYamanoteLine: YamanoteLine
    //MARK: - progress
    var progressDuration: Float = 1
    var progressTimer:Timer!
    // MARK: - 音声再生プロパティ
    var audioPlayer: AVAudioPlayer!

    // MARK: - 広告関係のプロパティ
    @IBOutlet weak private var bannerView: GADBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAdBannar()
        initializeProgress()
        startProgressTimer()
        configureViewQuizTextLabel()
        configureViewAnswerButton()
    }
    required init?(coder: NSCoder,level: YamanoteLineQuizLevel) {
        yamanoteLineGame = YamanoteLineGame(level: level)
        yamanoteLineAllShuffled = YamanoteLine.allCases.shuffled()
        selectedYamanoteLine = yamanoteLineAllShuffled.first!
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBAction func answerYamanoteLine(_ sender: UIButton) {
        print(selectedYamanoteLine)
        if yamanoteLineGame.answer(input: selectedYamanoteLine) {
            playSound(name: "correct")
            yamanoteLineGame.reset()
            resetPickerViewAndVariablesRelatedToPickerView()
            configureViewQuizTextLabel()
        } else {
            playSound(name: "miss")
            if yamanoteLineGame.missCount == 5 {
                audioPlayer.stop()
                performSegue(withIdentifier: "result", sender: nil)
            }
        }
    }

    private func configureViewQuizTextLabel() {
        quizTextLabel.text = yamanoteLineGame.displayQuizText()
        if DeviceType.isIPhone() {
            quizTextLabel.font = UIFont.boldSystemFont(ofSize: 35.0)
        } else {
            quizTextLabel.font = UIFont.boldSystemFont(ofSize: 70.0)
        }
    }
    private func resetPickerViewAndVariablesRelatedToPickerView() {
        yamanoteLineAllShuffled = yamanoteLineAllShuffled.shuffled()
        selectedYamanoteLine = yamanoteLineAllShuffled.first!
        answerPieckerView.reloadAllComponents()
    }
    private func configureViewAnswerButton() {
        answerButton.layer.borderWidth = 3
        answerButton.layer.borderColor = UIColor.init(named: "string")?.cgColor
        answerButton.layer.cornerRadius = 10
        answerButton.setTitleColor(UIColor.init(named: "string"), for: .normal)
        answerButton.setTitleColor(.gray, for: .disabled)
        if DeviceType.isIPhone() {
            answerButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        } else {
            answerButton.titleLabel?.font = UIFont.systemFont(ofSize: 50, weight: .bold)
        }
    }
    // MARK: - 広告関係のメソッド
    private func configureAdBannar() {
        // GADBannerViewのプロパティを設定
        bannerView.adUnitID = "\(GoogleAdID.gameBannerID)"
        bannerView.rootViewController = self
        // 広告読み込み
        bannerView.load(GADRequest())
    }

    //MARK: - progress
    private func initializeProgress() {
        progressDuration = 1.0
        answerTimerProgressView.tintColor = .black
        answerTimerProgressView.setProgress(progressDuration, animated: false)
    }
    private func startProgressTimer() {
        progressTimer
        = Timer
            .scheduledTimer(
                withTimeInterval: 0.01,
                repeats: true) { [weak self] _ in
                    self?.doneProgress()
                }
    }

    private func doneProgress() {
        let milliSecondProgress = 0.0001666
        progressDuration -= Float(milliSecondProgress)
        answerTimerProgressView.setProgress(progressDuration, animated: true)
        if progressDuration <= 0.0 {
            stopProgressTimer()
            guard let audioPlayer = audioPlayer else {
                performSegue(withIdentifier: "result", sender: nil)
                return
            }
            audioPlayer.stop()
            performSegue(withIdentifier: "result", sender: nil)
        }
    }

    private func stopProgressTimer(){
        progressTimer.invalidate()
    }
}
private extension GameViewController {
    @IBSegueAction
    func makeResultVC(coder: NSCoder, sender: Any?, segueIdentifier: String?) -> ResultViewController? {
        return ResultViewController(
            coder: coder,yamanoteLineGame: yamanoteLineGame
        )
    }

    @IBAction
    func backToGameViewController(segue: UIStoryboardSegue) {
    }
}


extension GameViewController: AVAudioPlayerDelegate {
    func playSound(name: String) {
        guard let path = Bundle.main.path(forResource: name, ofType: "mp3") else {
            print("音源ファイルが見つかりません")
            return
        }
        do {
            // AVAudioPlayerのインスタンス化
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))

            // AVAudioPlayerのデリゲートをセット
            audioPlayer.delegate = self

            audioPlayer.prepareToPlay()
            if audioPlayer.isPlaying {
                audioPlayer.stop()
                audioPlayer.currentTime = 0
            }
            // 音声の再生
            audioPlayer.play()
        } catch {
        }
    }
}

extension GameViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedYamanoteLine = yamanoteLineAllShuffled[row]
    }
}

extension GameViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        yamanoteLineAllShuffled.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return yamanoteLineAllShuffled.map { yamanoteLine in
            return yamanoteLine.textJapanese()
        }[row]
    }
}
