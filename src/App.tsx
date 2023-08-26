import {
  useState,
  SetStateAction,
  BaseSyntheticEvent,
  useRef,
  MutableRefObject,
  useEffect,
} from "react";
import reactLogo from "./assets/react.svg";
import Button from "react-bootstrap/Button";
import Form from "react-bootstrap/Form";
import Col from "react-bootstrap/Col";
import "./App.css";
import { Card, Modal, ModalBody, ModalHeader } from "react-bootstrap";
import SetUp from "./SetUp";
import GameInfo from "./GameInfo";

export interface Player {
  playerNumber: number;
  name: string;
  score: number[];
}

const minimumPlayers = [
  { playerNumber: 1, name: "", score: [] },
  { playerNumber: 2, name: "", score: [] },
];

function App() {
  const [, setState] = useState();
  const [gameMode, setGameMode] = useState("");
  const [winningScore, setWinningScore] = useState("");
  const [numOfPlayers, setNumOfPlayers] = useState(2);
  const [players, setPlayers] = useState(minimumPlayers as Player[]);
  const [gameReady, readyUp] = useState(false);
  const [currentPlayer, setCurrentPlayer] = useState({} as Player);
  const [winner, setWinner] = useState({} as Player);
  const [invalidScore, setValidity] = useState(false);
  const [isFirstTurn, setFirstTurn] = useState(true);
  const thisTurnScore: MutableRefObject<number> = useRef(0);

  function selectGameMode(mode: string) {
    setGameMode(mode as string);
  }

  function selectWinningScore(score: string) {
    setWinningScore(score as string);
  }

  function selectNumOfPlayers(num: number) {
    setNumOfPlayers(num);
    let currentPlayers = new Array(num);
    for (let i = 0; i < num; i++) {
      currentPlayers[i] = {
        playerNumber: i + 1,
        name: "",
        score: [],
      };
    }
    setPlayers(currentPlayers as Player[]);
  }

  function onChangePlayerName(playerNumber: number, name: string) {
    const player = players.find(
      (player) => player.playerNumber === playerNumber
    );
    if (player) {
      return (player.name = name);
    }
  }

  function isPlayerTurn(player: Player) {
    if (player.playerNumber === currentPlayer.playerNumber) return true;
    return false;
  }

  function getTotalScore(score: number[]) {
    let total = score.reduce((total, turn) => total + turn, 0);
    return total;
  }

  function submitTurnScore(e: BaseSyntheticEvent) {
    e.preventDefault();
    if (invalidScore) return;
    let score = Number(thisTurnScore.current);

    currentPlayer.score.push(score);

    const totalScore = getTotalScore(currentPlayer.score);
    const winScore = Number(winningScore.replace(",", ""));

    if (totalScore > winScore) {
      currentPlayer.score.pop();
      score = 0;
      currentPlayer.score.push(0);
    } else if (totalScore === winScore) {
      setWinner(currentPlayer);
    }

    if (score === 0 && countXs(currentPlayer) % 3 === 0) {
      if (gameMode === "10,000") {
        currentPlayer.score.push(-1000);
      } else {
        currentPlayer.score.push(-500);
      }
    }

    const currentPlayerIndex = players.findIndex(
      (player) => player.playerNumber === currentPlayer.playerNumber
    );
    if (currentPlayerIndex === players.length - 1) {
      setCurrentPlayer(players[0]);
    } else {
      setCurrentPlayer(players[currentPlayerIndex + 1]);
    }
    const scoreInput = document.getElementById("playerTurnScore") as any;
    console.log(scoreInput.value);
    scoreInput.value = "";
    setState({} as SetStateAction<undefined>);
  }

  function countXs(player: Player) {
    return player.score.filter((score) => score === 0).length;
  }

  function getXsCount(player: Player): string {
    let count = countXs(player);
    switch (count % 3) {
      default:
        return "Fresh Slate";
      case 1:
        return "X";
      case 2:
        return "X X";
    }
  }

  function getXsStyle(player: Player) {
    if (getXsCount(player) === "Fresh Slate") {
      return { color: "green" };
    } else return { color: "red" };
  }

  function continueToGame(e: BaseSyntheticEvent) {
    e.preventDefault();
    readyUp(true);
  }

  function onScoreChange(e: BaseSyntheticEvent) {
    const value = e.target.value as unknown as number;
    scoreValidation(value);
    thisTurnScore.current = value;
  }

  function scoreValidation(score: number) {
    return setValidity(score % 50 !== 0);
  }

  function back() {
    const currentPlayerIndex = players.findIndex(
      (player) => player.playerNumber === currentPlayer.playerNumber
    );
    if (currentPlayerIndex === 0) {
      setCurrentPlayer(players[players.length - 1]);
      players[players.length - 1].score.pop();
    } else {
      setCurrentPlayer(players[currentPlayerIndex - 1]);
      players[currentPlayerIndex - 1].score.pop();
    }
  }

  useEffect(() => {
    setCurrentPlayer(players[0]);
  }, [players.length]);

  useEffect(() => {
    if (players[0].score.length === 0) {
      setFirstTurn(true);
    } else setFirstTurn(false);
  });

  return (
    <div className="">
      {/* <h1>Thousands Dice Game</h1> */}
      {!gameReady && (
        <SetUp
          gameMode={gameMode}
          winningScore={winningScore}
          numOfPlayers={numOfPlayers}
          players={players}
          selectGameMode={selectGameMode}
          selectWinningScore={selectWinningScore}
          selectNumOfPlayers={selectNumOfPlayers}
          onChangePlayerName={onChangePlayerName}
          continueToGame={continueToGame}
        />
      )}
      {gameReady && (
        <GameInfo
          gameMode={gameMode}
          winningScore={winningScore}
          numOfPlayers={numOfPlayers}
          players={players}
          getTotalScore={getTotalScore}
          getXsCount={getXsCount}
          getXsStyle={getXsStyle}
        />
      )}
      {gameReady && (
        <div className="d-flex flex-column flex-lg-row justify-content-between">
          <Card className="w-100">
            <Card.Title>
              <b>{currentPlayer.name.toLocaleUpperCase()}</b>
            </Card.Title>
            <Card.Subtitle>{getTotalScore(currentPlayer.score)}</Card.Subtitle>
            <Card.Body style={getXsStyle(currentPlayer)}>
              {getXsCount(currentPlayer)}
            </Card.Body>
            <Form>
              <Form.Group controlId="playerTurnScore">
                <Form.Control
                  type="number"
                  placeholder="Please enter your score"
                  step={50}
                  isInvalid={invalidScore}
                  onChange={onScoreChange}
                  autoFocus
                ></Form.Control>
                <div className="d-flex flex-row justify-content-around">
                  {isFirstTurn === false && (
                    <Button variant="secondary" className="mt-2" onClick={back}>
                      Back
                    </Button>
                  )}
                  <Button
                    variant="success"
                    type="submit"
                    className="mt-2"
                    onClick={submitTurnScore}
                  >
                    Submit
                  </Button>
                </div>
              </Form.Group>
            </Form>
          </Card>
        </div>
      )}
      <Modal show={!!winner.name} onHide={() => setWinner({} as Player)}>
        <ModalHeader>Congratulations!!!</ModalHeader>
        <ModalBody>{winner.name}, you are the winner</ModalBody>
      </Modal>
    </div>
  );
}

export default App;
