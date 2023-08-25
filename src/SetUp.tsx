import React, { BaseSyntheticEvent } from 'react'
import { Button, Form } from 'react-bootstrap'
import { Player } from './App'

interface SetUpProps {
  gameMode: string,
  selectGameMode: (gameMode: string) => void,
  winningScore: string,
  selectWinningScore: (score: string) => void,
  numOfPlayers: number,
  selectNumOfPlayers: (players: number) => void,
  onChangePlayerName: (playerNumber: number, name: string) => void,
  players: Player[]
  continueToGame: (e: BaseSyntheticEvent) => void
}

function SetUp(props: SetUpProps) {
  return (
    <div className="card">
    <span className='d-flex flex-col justify-content-between'>
      <div className='d-flex flex-row'>
        <strong>Game Mode: </strong>
        <p className='mx-2'>{!props.gameMode ? 'Please select a game mode' : props.gameMode}</p>
      </div>
      <div className='d-flex flex-row'>
        <strong>Winning Score: </strong>
        <p className='mx-2'>{!props.winningScore ? 'Please select winning score' : props.winningScore}</p>
      </div>
    </span>
    <span>
      <strong>Number of Players:</strong> {props.numOfPlayers}
    </span>
    {!props.gameMode && <p>Please select your game mode</p>}
    {!props.gameMode && <div className="d-flex flex-row justify-content-around">
      <Button onClick={() => props.selectGameMode('1,000')}>1,000</Button>
      <Button onClick={() => props.selectGameMode('10,000')}>10,000</Button>
    </div>}
    {!!props.gameMode && !props.winningScore && <p>Please select your winning score</p>}
    {!!props.gameMode && !props.winningScore && <div className="d-flex flex-row justify-content-around">
      {props.gameMode !== '10,000' && <Button onClick={() => props.selectWinningScore('5,000')}>5,000</Button>}
      <Button onClick={() => props.selectWinningScore('10,000')}>10,000</Button>
      <Button onClick={() => props.selectWinningScore('15,000')}>15,000</Button>
      </div>}
    {!!props.gameMode && !!props.winningScore && <p>Select numbers of players in your game &#40;2-6&#41;</p>}
    {!!props.gameMode && !!props.winningScore && <p style={{color: 'red'}}>Note: You cannot win without a name!</p>}
    {!!props.gameMode && !!props.winningScore && <input type='range' min={2} max={6} onChange={(e) => props.selectNumOfPlayers(e.target.value as unknown as number)} value={props.numOfPlayers}></input>}
    <Form>
    {!!props.gameMode && !!props.winningScore && props.players.map((player, i) => (
    <Form.Group key={'Player' + player.playerNumber} controlId={`Player${i}`}>
      <Form.Label>Player {player.playerNumber}</Form.Label>
      <Form.Control type='text' placeholder='Player Name' onChange={(e) => props.onChangePlayerName(player.playerNumber, e.target.value)}/>
    </Form.Group>
    ))}
    <br />
    {!!props.gameMode && !!props.winningScore && <Button type='submit' onClick={props.continueToGame}>Continue</Button>}
    </Form>
  </div>
  )
}

export default SetUp