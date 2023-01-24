import { useState, SetStateAction, BaseSyntheticEvent, useRef, MutableRefObject, useEffect } from 'react'
import reactLogo from './assets/react.svg'
import Button from 'react-bootstrap/Button'
import Form from 'react-bootstrap/Form'
import Col from 'react-bootstrap/Col'
import './App.css'
import { Card, Modal, ModalBody, ModalHeader } from 'react-bootstrap'


interface Player {
  playerNumber: number
  name: string;
  score: number[];
  xs: number[];
}

const minimumPlayers = [{playerNumber: 1, name: '', score: [], xs: []},{playerNumber: 2, name: '', score: [], xs: []}]

function App() {
  const [, setState] = useState()
  const [gameMode, setGameMode] = useState('')
  const [winningScore, setWinningScore] = useState('')
  const [numOfPlayers, setNumOfPlayers] = useState(2)
  const [players, setPlayers] = useState(minimumPlayers as Player[])
  const [gameReady, readyUp] = useState(false)
  const [currentPlayer, setCurrentPlayer] = useState({} as Player)
  const [winner, setWinner] = useState({} as Player)
  const thisTurnScore: MutableRefObject<number> = useRef(0)
  

  function selectGameMode (mode: string) {
    setGameMode(mode as string)
  }

  function selectWinningScore (score: string) {
    setWinningScore(score as string)
  }

  function selectNumOfPlayers (num: number) {
    setNumOfPlayers(num);
    let currentPlayers = new Array(num);
    for(let i = 0; i < num ; i++) {
      currentPlayers[i] = {
        playerNumber: i + 1,
        name: '',
        score: [],
        xs: [],
      }
    }
    setPlayers(currentPlayers as Player[])
  }

  function onChangePlayerName (playerNumber: number, name: string) {
    const player = players.find((player) => (player.playerNumber === playerNumber))
    if (player) {
      return player.name = name
    }
  }

  function isPlayerTurn(player: Player) {
    if (player.playerNumber === currentPlayer.playerNumber) return true
    return false
  }

  function getTotalScore(score: number[]) {
    let total = score.reduce((total, turn) => 
      total + turn, 0
    )
    return total;
  }

  function submitTurnScore () {
    let score = Number(thisTurnScore.current)

    if (score === 0) {
      currentPlayer.xs.push(score)
    } else {
      currentPlayer.score.push(score)
    }
    
    const totalScore = getTotalScore(currentPlayer.score)
    const winScore = Number(winningScore.replace(',', ''))

    
    if (totalScore > winScore) {
      currentPlayer.score.pop()
      score = 0
      currentPlayer.xs.push(0)
    } else if (totalScore === winScore) {
      setWinner(currentPlayer)
    }

    if (score === 0 && currentPlayer.xs.length % 3 === 0) {
      if (gameMode === '10,000') {
        currentPlayer.score.push(-1000)
      } else {
        currentPlayer.score.push(-500)
      }
    }

    const currentPlayerIndex = players.findIndex((player) => player.playerNumber === currentPlayer.playerNumber )
    if (currentPlayerIndex === players.length - 1) {
      setCurrentPlayer(players[0])
    } else {
      setCurrentPlayer(players[currentPlayerIndex + 1])
    }
    setState({} as SetStateAction<undefined>)
  }

  function getXsCount (xs: number[]): string {
    switch (xs.length % 3) {
      default: return "Fresh Slate"
      case 1: return "X"
      case 2: return "X X"
      case 3: return "X X X"
    }
  }

  function getXsStyle(xs: number[]) {
    if (getXsCount(xs) === "Fresh Slate") {
      return {color: 'green'}
    } else return {color: 'red'}
  }

  function continueToGame (e: BaseSyntheticEvent) {
    e.preventDefault()
    readyUp(true)
  }

  useEffect(() => {
    setCurrentPlayer(players[0])
  }, [players.length])

  return (
    <div className='App'>
      {/* <h1>Thousands Dice Game</h1> */}
      <div className="card">
        <span className='d-flex flex-col justify-content-between'>
          <div className='d-flex flex-row'>
            <strong>Game Mode: </strong>
            <p className='mx-2'>{!gameMode ? 'Please select a game mode' : gameMode}</p>
          </div>
          <div className='d-flex flex-row'>
            <strong>Winning Score: </strong>
            <p className='mx-2'>{!winningScore ? 'Please select winning score' : winningScore}</p>
          </div>
        </span>
        <span>
          <strong>Number of Players:</strong> {numOfPlayers}
        </span>
        {!gameMode && <p>Please select your game mode</p>}
        {!gameMode && <div className="d-flex flex-row justify-content-around">
          <Button onClick={() => selectGameMode('1,000')}>1,000</Button>
          <Button onClick={() => selectGameMode('10,000')}>10,000</Button>
        </div>}
        {!!gameMode && !winningScore && <p>Please select your winning score</p>}
        {!!gameMode && !winningScore && <div className="d-flex flex-row justify-content-around">
          {gameMode !== '10,000' && <Button onClick={() => selectWinningScore('5,000')}>5,000</Button>}
          <Button onClick={() => selectWinningScore('10,000')}>10,000</Button>
          <Button onClick={() => selectWinningScore('15,000')}>15,000</Button>
          </div>}
        {!!gameMode && !!winningScore && !gameReady && <p>Select numbers of players in your game &#40;2-6&#41;</p>}
        {!!gameMode && !!winningScore && !gameReady && <p style={{color: 'red'}}>Note: You cannot win without a name!</p>}
        {!!gameMode && !!winningScore && !gameReady && <input type='range' min={2} max={6} onChange={(e) => selectNumOfPlayers(e.target.value as unknown as number)} value={numOfPlayers}></input>}
        <Form>
        {!!gameMode && !!winningScore && !gameReady && players.map((player, i) => (
        <Form.Group key={'Player' + player.playerNumber} controlId={`Player${i}`}>
          <Form.Label>Player {player.playerNumber}</Form.Label>
          <Form.Control type='text' placeholder='Player Name' onChange={(e) => onChangePlayerName(player.playerNumber, e.target.value)}/>
        </Form.Group>
        ))}
        <br />
        {!!gameMode && !!winningScore && !gameReady && <Button type='submit' onClick={continueToGame}>Continue</Button>}
        </Form>
      </div>
      {gameReady &&
        <div className='d-flex flex-column flex-lg-row justify-content-between'>
          {players.map((player) => <Card className='w-100'>
            <Card.Title>{player.name}</Card.Title>
            <Card.Subtitle>{getTotalScore(player.score)}</Card.Subtitle>
            <Card.Body style={getXsStyle(player.xs)}>{getXsCount(player.xs)}</Card.Body>
            {isPlayerTurn(player) && 
              <Form>
              <Form.Group controlId='playerTurnScore'>
              <Form.Label>Your score this turn</Form.Label>
              <Form.Control type='number' placeholder='Please enter your score' onChange={(e) => thisTurnScore.current = e.target.value as unknown as number} autoFocus></Form.Control>
              <Button variant='success' type='submit' className='mt-2' onClick={submitTurnScore}>Submit</Button>
              </Form.Group>
              </Form>}
          </Card>)}
        </div>}
        <Modal show={!!winner.name} onHide={() => setWinner({} as Player)}>
          <ModalHeader>Congratulations!!!</ModalHeader>
          <ModalBody>{winner.name}, you are the winner</ModalBody>
          </Modal>
    </div>
  )
}

export default App
