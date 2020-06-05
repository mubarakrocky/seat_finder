import React from 'react';
import ReactDOM from 'react-dom';

class SeatFinder extends React.Component {
    render() {
        return(
            <React.Fragment>
                <h1>Seats Finder</h1>
                <div className="row">
                    <div className="col">
                        <SeatForm />
                    </div>
                    <div className="col">
                        <ResultArea />
                    </div>
                </div>
            </React.Fragment>
        );
    }
};

class SeatForm extends React.Component {
    constructor(props) {
        super(props);

        this.inputValues = {
            'seats_json': '',
            'no_of_seats': 1
        };

        this.onSubmit = this.onSubmit.bind(this);
        this.onChange = this.onChange.bind(this);
    }

    render() {
        return(
            <form id="seat-finder-form" onSubmit={ this.onSubmit }>
                <TextArea name="seats_json" label="Please input the seats JSON" onchange={ this.onChange } />
                <SelectBox name="no_of_seats" label="Please select number of seats" onchange={ this.onChange }
                           values={ [1, 2, 3, 4, 5, 6, 7, 8, 9] }/>
                <SubmitButton />
            </form>
        );
    }

    onSubmit(event) {
        event.preventDefault();
        // Clear the result area
        ReactDOM.render(<span />, document.getElementById('result'));

        this.post(this.inputValues, (response) => {
            // Render the result
            ReactDOM.render(<Result results={ response } />, document.getElementById('result'));
        }, (errors) => {
            alert(errors);
        });
    }

    post(data, succesCallback, errorCallback) {
        const xhr = new XMLHttpRequest();

        xhr.onload = () => {
            try {
                // print JSON response
                if (xhr.status >= 200 && xhr.status < 300) {
                    succesCallback.call(this, JSON.parse(xhr.responseText));
                } else {
                    errorCallback.call(this, JSON.parse(xhr.responseText));
                }
            } catch (e) {
                alert('Bad response from server');
            }
        };

        xhr.open('POST', '/seats/find.json');

        xhr.setRequestHeader('Content-Type', 'application/json');

        xhr.setRequestHeader('X-CSRF-Token', document.getElementsByName("csrf-token")[0].content);

        xhr.send(JSON.stringify(data));
    }

    onChange(event) {
        this.inputValues[event.target.name] = event.target.value;
    }
};

function TextArea(props)  {
    return(
        <div className="form-component">
            <label>{ props.label }</label>
            <textarea type="text" name={ props.name } onChange={props.onchange} rows="20" cols="60"/>
        </div>
    );
}

function SelectBox(props)  {
    return(
        <div className="form-component">
            <label>{ props.label }</label>
            <select onChange={props.onchange} name={props.name}>
                {
                    props.values.map((value) => <option key={value}>{ value }</option>)
                }
            </select>
        </div>
    );
}

function SubmitButton() {
    return(
        <div className="form-component">
            <input type="submit"/>
        </div>
    );
}

function ResultArea() {
    return(
        <div id="result"></div>
    );
}

function Result(props) {
    return(
        <div>
            <h3>Best Available Seats Are:</h3>
            <ul>
                {
                    props.results.map((seat) => <li key={ seat.id }>{ seat.id } </li>)
                }
            </ul>
        </div>
    );
}

ReactDOM.render(<SeatFinder />, document.getElementById('root'));
