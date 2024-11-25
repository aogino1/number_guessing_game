#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate a random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Prompt for username
echo "Enter your username:"
read USERNAME

# Username should be 22 characters or less
if [[ ${#USERNAME} -gt 22 ]]
then
  exit
fi

# Check if user exists
USER_INFO=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

# If user doesn't exist
if [[ -z $USER_INFO ]]
then
  # Insert new user
  INSERT_USER=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, 0)")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else
  # Parse existing user info
  echo "$USER_INFO" | while IFS="|" read GAMES_PLAYED BEST_GAME
  do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# Start game
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0

# Game loop
while true
do
  read GUESS
  
  # Check if input is an integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi
  
  # Increment guess counter
  ((NUMBER_OF_GUESSES++))
  
  # Compare guess with secret number
  if [[ $GUESS -eq $SECRET_NUMBER ]]
  then
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    
    # Update user stats
    if [[ -z $USER_INFO ]]
    then
      # First game for new user
      UPDATE_STATS=$($PSQL "UPDATE users SET games_played = 1, best_game = $NUMBER_OF_GUESSES WHERE username = '$USERNAME'")
    else
      # Update existing user stats
      echo "$USER_INFO" | while IFS="|" read GAMES_PLAYED BEST_GAME
      do
        # Calculate new best game
        if [[ $BEST_GAME -eq 0 || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]
        then
          BEST_GAME=$NUMBER_OF_GUESSES
        fi
        
        # Increment games played
        ((GAMES_PLAYED++))
        
        # Update database
        UPDATE_STATS=$($PSQL "UPDATE users SET games_played = $GAMES_PLAYED, best_game = $BEST_GAME WHERE username = '$USERNAME'")
      done
    fi
    break
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
#   then
#     echo "It's lower than that, guess again:"
#   else
#     echo "It's higher than that, guess again:"
#   fi
# done