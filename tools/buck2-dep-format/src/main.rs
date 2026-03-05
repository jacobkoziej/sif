// SPDX-License-Identifier: MPL-2.0
//
// main.rs -- buck2-dep-format
// Copyright (C) 2026  Jacob Koziej <jacobkoziej@gmail.com>

use clap::Parser;
use path_absolutize::Absolutize;
use std::env::current_dir;
use std::error::Error;
use std::ffi::OsString;
use std::fs;
use std::fs::File;
use std::io;
use std::io::{BufWriter, Write};
use std::path::PathBuf;
use std::process::Command;

/// buck2 dependency file formatter
#[derive(Parser)]
#[command(version, about)]
struct Args {
    /// Current working directory
    #[arg(short, long)]
    cwd: Option<PathBuf>,

    /// Path to input dep file
    #[arg(short, long)]
    input: PathBuf,

    /// Top-level target for which to extract dependencies
    #[arg(short, long)]
    target: String,

    /// Optional command to run
    #[arg(trailing_var_arg = true)]
    command: Vec<OsString>,
}

fn main() -> Result<(), Box<dyn Error>> {
    let args = Args::parse();

    if let Some((program, args)) = args.command.split_first() {
        Command::new(program).args(args).spawn()?.wait()?;
    }

    let contents = fs::read_to_string(&args.input)?;
    let targets = depfile::parse(&contents).unwrap();

    let cwd: PathBuf = args.cwd.unwrap_or(current_dir()?);

    let abs_path = |p: &str| -> PathBuf {
        PathBuf::from(p)
            .absolutize_from(&cwd)
            .unwrap()
            .to_path_buf()
    };

    let deps: Vec<PathBuf> = targets
        .recurse_deps(&args.target.to_string())
        .map(abs_path)
        .collect();

    let output: Box<dyn Write> = if args.command.is_empty() {
        Box::new(io::stdout())
    } else {
        Box::new(File::create(args.input)?)
    };

    let mut writer = BufWriter::new(output);

    for dep in deps {
        writer.write_all(dep.strip_prefix(&cwd).unwrap().to_str().unwrap().as_bytes())?;
        writer.write_all(&[b'\n'])?;
    }

    Ok(())
}
