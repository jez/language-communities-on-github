# Language Communities on GitHub

This repo is the result of a class project for the course 05-320 Social Web at
CMU. I took it in the Spring 2017 semester.

For the class project, we decided to answer the question:

> ### How does social activity on GitHub vary by programming language?

## Project Overview

- [Proposal Writeup](description/description.pdf)
- [Proposal Presentation](intro-presentation/intro-presentation.pdf)
- [Midterm Checkpoint](midterm-presentation/midterm-presentation.pdf)

## Results

To see some of our preliminary results, see:

- [Midterm Checkpoint](midterm-presentation/midterm-presentation.pdf)
- [Visualizations](results/images/)

## Methodology

We're getting data from the GitHub API.

- [github-data.db](github-data/github-data.db)
  - SQLite database to play around with our data
- [driver.sh](github-data/driver.sh)
  - Use our data pipeline to get new or more data for yourself
  - Requires `bash`, `curl`, GNU `grep`, `jq`, and `sqlite3`

To randomly sample repos for this project, we used this query on GitHub Search:

```
language:LANGUAGE stars:1000..4000 pushed:>2017-01-01
```

## License

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://jez.io/MIT-LICENSE.txt)
