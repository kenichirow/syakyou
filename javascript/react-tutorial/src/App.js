import React, { Component } from 'react';
import './App.css';

class Board extends Component {
    constructor () {
        super();
        this.state = {
            squares: Array(9).fill(null),
        };
    }

    handleClick(i) {
        console.log(this.state.squares)
        const new_squares = this.state.squares.slice();
        new_squares[i] = 'X';
        this.setState({squares: new_squares});
    }

    renderSquare(i) {
        return <Square value={this.state.squares[i]}
                onClick={() => this.handleClick(i)}
            />;
    }

    render() {
        const status = "Next Paleyer: X";

        return (
            <div>
             <div className="status">{status}</div>
                <div className="board-row">
                    {this.renderSquare(0)}
                    {this.renderSquare(1)}
                    {this.renderSquare(2)}
                </div>
                <div className="board-row">
                    {this.renderSquare(3)}
                    {this.renderSquare(4)}
                    {this.renderSquare(5)}
                </div>
                <div className="board-row">
                    {this.renderSquare(6)}
                    {this.renderSquare(7)}
                    {this.renderSquare(8)}
                </div>
            </div>
        );
    }
}

function Square(props) {
    return (
        <button className="square" onClick={() => props.onClick()}>
        {props.value}
        </button>
    );
}
    


class App extends Component {
  render() {
    return (
      <div className="game">
        <div className="game-board">
            <Board />
        </div>
        <div className="game-info">
            <div></div>
            <ol>
            </ol>
        </div>
      </div>
    );
  }
}

export default App;
