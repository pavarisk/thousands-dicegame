import { useState, SetStateAction } from 'react'
import reactLogo from './assets/react.svg'
import Button from 'react-bootstrap/Button'
import Form from 'react-bootstrap/Form'
import Col from 'react-bootstrap/Col'
import './App.css'


interface Player {
  playerNumber: number
  name: string;
  score: number[]
}

const minimumPlayers = [{playerNumber: 1, name: '', score: []},{playerNumber: 2, name: '', score: []}]

function App() {
  const [, setState] = useState()
  const [gameMode, setGameMode] = useState('')
  const [winningScore, setWinningScore] = useState('')
  const [numOfPlayers, setNumOfPlayers] = useState(2)
  const [players, setPlayers] = useState(minimumPlayers as Player[])
  const [gameReady, readyUp] = useState(false)
  

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
        score: []
      }
    }
    setPlayers(currentPlayers as Player[])
  }

  function onChangePlayerName (playerNumber, name) {
    const player = players.find((player) => (player.playerNumber === playerNumber))
    if (player) {
      return player.name = name
    }
  }

  function continueToGame (e) {
    e.preventDefault()
    readyUp(true)
  }

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
        {!!gameMode && !!winningScore && !gameReady && <input type='range' min={2} max={6} onChange={(e) => selectNumOfPlayers(e.target.value)} value={numOfPlayers}></input>}
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
        <div>
          
        </div>}
    </div>
  )
}

export default App
