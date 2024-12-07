### Fix RTL
- Fix bug where when victory checking, wrap-around between rows can occur leading to false positive


### Optimization
- Switch from using 64 bit vector winning_pieces to using 11 to mark a winning piece on the board reg


### Testing
- Write a test for wrap-around rows and columns when victory checking, ensuring no false positives occur
- Write a test for a tie case