from flask import Flask, render_template, request, redirect, url_for, flash

app = Flask(__name__)
# Set a secret key for flash messages to work
app.config['SECRET_KEY'] = 'a_very_secret_key_that_you_should_change'

# A simple list to act as our in-memory database for notes
notes = []

@app.route('/', methods=['GET', 'POST'])
def home():
    """
    Main route for the application.
    - GET request: Renders the home page and displays existing notes.
    - POST request: Handles the form submission to add a new note.
    """
    if request.method == 'POST':
        # Get the note content from the form
        note_content = request.form.get('note')

        # Check if the note is not empty before adding
        if note_content:
            notes.append(note_content)
            flash('Note added successfully!', 'success')
        else:
            flash('Note cannot be empty!', 'error')

        # Redirect back to the home page to prevent form resubmission
        return redirect(url_for('home'))

    # Render the index.html template and pass the list of notes to it
    return render_template('index.html', notes=notes)

if __name__ == '__main__':
    # Run the application in debug mode for development
    # The host='0.0.0.0' argument is crucial for Docker, as it tells Flask to listen on all public IPs.
    app.run(host='0.0.0.0', debug=True)