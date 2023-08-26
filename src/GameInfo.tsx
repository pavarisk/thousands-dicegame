import React from "react";
import { Player } from "./App";
interface GameInfoProps {
  gameMode: string;
  winningScore: string;
  numOfPlayers: number;
  players: Player[];
  getTotalScore: (score: number[]) => number;
  getXsCount: (player: Player) => string;
  getXsStyle: (player: Player) => {};
}

function GameInfo(props: GameInfoProps) {
  const {
    gameMode,
    winningScore,
    numOfPlayers,
    players,
    getTotalScore,
    getXsCount,
    getXsStyle,
  } = props;

  function getLastScores(score: number[], placement: number) {
    if (score.length >= placement) {
      return placement !== 1
        ? score.slice(-placement, -placement + 1)[0]
        : score.slice(-placement)[0];
    }
    return " -- ";
  }

  return (
    <div className="w-100">
      <span className="d-flex justify-content-between">
        <div className="d-flex flex-row">
          <strong>Game Mode: </strong>
          <p className="mx-2">{gameMode}</p>
        </div>
        <div className="d-flex flex-row">
          <strong>Winning Score: </strong>
          <p className="mx-2">{winningScore}</p>
        </div>
        <strong>Number of Players:</strong> {numOfPlayers}
      </span>
      <table className="table table-bordered w-100">
        <thead>
          <th>Name and X's</th>
          <th>Total</th>
          <th>Last Score</th>
          <th>2nd to Last</th>
          <th>3rd to Last</th>
        </thead>
        <tbody>
          {players.map((player) => (
            <tr>
              <td className="d-flex flex-column">
                <b>{player.name}</b>
                <p style={getXsStyle(player)}>{getXsCount(player)}</p>
              </td>
              <td>
                <b>{getTotalScore(player.score)}</b>
              </td>
              <td>{getLastScores(player.score, 1)}</td>
              <td>{getLastScores(player.score, 2)}</td>
              <td>{getLastScores(player.score, 3)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default GameInfo;
