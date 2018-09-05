//
//  ViewController.swift
//  TTT
//
//  Created by Quang Nguyen on 9/4/18.
//  Copyright © 2018 Quang Nguyen. All rights reserved.
//

import UIKit

enum Color {
  case red
  case blue
}

enum gameError: Error {
  case invalidMoveError
  case gameOverError
}

@IBDesignable
class TTTSquare: UIButton {
  
  @IBInspectable var position: NSNumber! {
    didSet {
      print("didSet position, position")
    }
  }
  
  required init(coder aDecoder: NSCoder)  {
    super.init(coder: aDecoder)!
  }
  
}


class Player {
  var color: Color
  var moveList: [Move]
  
  init(_ color: Color ){
    self.color = color
    self.moveList = []
  }
  func name() -> String {
    if color == .red {
      return "RED"
    } else {
      return "BLUE"
    }
  }
  
  func makeMove(on squarePos: Int, for game: Game) throws {
    guard !game.isOver() else {
      throw gameError.gameOverError
    }
    
    let newMove = Move(on: squarePos, by: self, at: game.turn)
    guard !newMove.isInvalidMoveForGame(game) else {
      throw gameError.invalidMoveError
    }
    
    moveList.append(newMove)
  }
  
  func recentMove() -> Move? {
    return moveList.last
  }
  
  // Set of all positions player has captured
  func capturedPos() -> Set<Int> {
    var capturedPosSet: Set<Int> = []
    for move in moveList {
      capturedPosSet.insert(move.squarePos)
    }
    return capturedPosSet
  }
  
  func recentMoveIsWinningMove() -> Bool {
    // Check if player has recent move
    guard let playerRecentMove = recentMove() else{
      return false
    }
    let playerCapturedPos = capturedPos()
    for winningCombination in playerRecentMove.allWinningCombinations() {
      if winningCombination.isSubset(of: playerCapturedPos) {
        return true
      }
    }
    return false
  }
  
  func reset() {
    moveList = []
  }
}

class Move {
  // The square position the move is made on
  var squarePos: Int
  // The player who made the move
  var player: Player
  // The turn on which the move is made
  var turn: Int
  
  init(on squarePos: Int, by player: Player, at turn: Int){
    self.squarePos = squarePos
    self.player = player
    self.turn = turn
  }
  
  func isInvalidMoveForGame(_ game: Game) -> Bool {
    for player in game.players {
      if player.capturedPos().contains(self.squarePos) {
        return true
      }
    }
    return false
  }
  // Returns a combination of position that forms a vertical win with move's `squarePos`
  func verticalSet() -> Set<Int> {
    if squarePos % 3 == 1 { // If left col
      return [1, 4, 7]
    } else if squarePos % 3 == 2 { // If mid col
      return [2, 5, 8]
    } else {
      return [3, 6, 9]
    }
  }
  
  // Returns a combination of position that forms a horizontal win with move's `squarePos`
  func horizontalSet() -> Set<Int> {
    if squarePos < 4 { // If top row
      return [1, 2, 3]
    } else if squarePos < 7 { // If mid row
      return [4, 5, 6]
    } else {
      return [7, 8, 9]
    }
  }
  
  // Returns a combination of position that forms a TL->BR win with move's `squarePos`
  func topLeftToBotRightDiagonalSet() -> Set<Int> {
    let diagonalSet: Set<Int> = [1, 5, 9]
    if diagonalSet.contains(squarePos) {
      return diagonalSet
    } else {
      return []
    }
  }
  
  // Returns a combination of position that forms a BL->TR win with move's `squarePos`
  func botLeftToTopRightDiagonalSet() -> Set<Int> {
    let diagonalSet: Set<Int> = [3, 5, 7]
    if diagonalSet.contains(squarePos) {
      return diagonalSet
    } else {
      return []
    }
  }
  
  // Set of winning combinations for a certain move
  func allWinningCombinations() -> [Set<Int>] {
    var winningCombs = [verticalSet(), horizontalSet()]
    if !topLeftToBotRightDiagonalSet().isEmpty {
      winningCombs.append(topLeftToBotRightDiagonalSet())
    } else if !botLeftToTopRightDiagonalSet().isEmpty{
      winningCombs.append(botLeftToTopRightDiagonalSet())
    }
    return winningCombs
  }
  
}

class Game {
  var players: [Player]
  var turn = 0
  
  init() {
    let redPlayer = Player(Color.red)
    let bluPlayer = Player(Color.blue)
    players = [redPlayer, bluPlayer]
  }
  
  func restart(){
    for player in players {
      player.reset()
    }
    turn = 0
  }
  
  func currPlayer() -> Player {
    return players[turn % players.count]
  }
  
  func winner() -> Player? {
    var winner: Player?
    for player in players {
      if player.recentMoveIsWinningMove() {
        winner = player
      }
    }
    return winner
  }
  
  func takeNextTurn(on squarePos: Int) throws {
    let player = currPlayer()
    try player.makeMove(on: squarePos, for: self)
    turn += 1
  }
  
  func isWon() -> Bool {
    for player in players {
      if player.recentMoveIsWinningMove() {
        return true
      }
    }
    return false
  }
  
  func isTied() -> Bool {
    var totalMoves = 0
    let maxMoves = 9
    for player in players {
      totalMoves += player.moveList.count
    }
    return !self.isWon() && totalMoves >= maxMoves
  }
  
  func isOver() -> Bool {
    return self.isTied() || self.isWon()
  }
}

class ViewController: UIViewController {
  
  @IBOutlet weak var winnerLabel: UILabel!
  @IBOutlet weak var TTTgrid: UIStackView!
  @IBAction func resetButtonPressed(_ sender: UIButton) {
    game.restart()
    
    // Reset colors
    for rowStack in TTTgrid.subviews {
      for button in rowStack.subviews {
        button.backgroundColor = UIColor.lightGray
      }
    }
    
    winnerLabel.isHidden = true

  }
  
  @IBAction func squareButtonPressed(_ sender: TTTSquare!) {
    // Try taking next turn, display Error if not
    do {
      try game.takeNextTurn(on: Int(sender.position))
      
      // Set color of square
      if game.currPlayer().color == .red {
        sender.backgroundColor = UIColor.red
      } else {
        sender.backgroundColor = UIColor.blue
      }
    } catch gameError.invalidMoveError {
      print("INVALID MOVE")
    } catch gameError.gameOverError {
      print("GAME ALREDY OVER")
    } catch {
      print("UNEXPECTED ERROR")
    }
    
    if game.isOver() {
    winnerLabel.isHidden = false
      if game.isTied() {
        winnerLabel.text = "GAME IS TIED"
      } else if game.isWon() {
        winnerLabel.text = "CONGRATZ \(game.winner()?.name() ?? "NOBODY") WON"
      }
    }
  }
  
  var game = Game()
  override func viewDidLoad() {
    super.viewDidLoad()
    winnerLabel.isHidden = true
    
    // Do any additional setup after loading the view, typically from a nib.
  }


}

