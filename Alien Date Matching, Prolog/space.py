with open('file.txt', 'r') as f:
    lines = f.readlines()

# remove spaces
lines = [line.replace(' ', '') for line in lines]
lines = [line.replace('\n', '') for line in lines]
lines = [line.replace('\t', '') for line in lines] 

# finally, write lines in the file
with open('file.txt', 'w') as f:
    f.writelines(lines)