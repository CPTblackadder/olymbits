use std::{io, ops::{Index, IndexMut, Add, Mul, Sub, Div},  iter::{Sum, zip}, cmp::PartialEq, convert::TryInto};

macro_rules! parse_input {
    ($x:expr, $t:ident) => ($x.trim().parse::<$t>().unwrap())
}

const COMMANDS: [Command; 4]= [Command::UP, Command::RIGHT, Command:: DOWN, Command::LEFT];
const ARCHERY_MAX: i32 = 20;
/**
 * Auto-generated code below aims at helping you parse
 * the standard input according to the problem statement.
 **/
fn main() {
    let mut input_line = String::new();
    io::stdin().read_line(&mut input_line).unwrap();
    let player_idx = parse_input!(input_line, i32);
    let mut input_line = String::new();
    io::stdin().read_line(&mut input_line).unwrap();
    let nb_games = parse_input!(input_line, i32);

    for turn in 0..100 {
        heuristic_game_loop(player_idx, turn);
    }
}

#[derive(Debug)]
enum OneOrFour<T> {
    One(T),
    Four(CommandList<T>),
}

#[derive(PartialEq, PartialOrd, Clone, Copy)]
struct OrderedFloat(f32);

impl Eq for OrderedFloat {
}

impl Ord for OrderedFloat {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.0.total_cmp(&other.0)
    }
}

fn euclidean_distance<T>(x: T, y: T) -> f32
where T: Mul<Output=T> + Into<f32> + Copy  {
    (Into::<f32>::into(x * x) + Into::<f32>::into(y * y)).sqrt()
}

fn maybe_euclidean_distance<T>(x: T, y: T) -> Option<f32>
where T: Mul<Output=T> + TryInto<f32> + Copy  {
    Some((TryInto::<f32>::try_into(x * x).ok()? + TryInto::<f32>::try_into(y * y).ok()?).sqrt())
}

fn euclidean_distance_i32(x: i32, y: i32) -> f32
{
    ((x * x + y * y) as f32).sqrt()
}

// output = output_start + ((output_end - output_start) / (input_end - input_start)) * (input - input_start)
fn map_from_range_to_range<T>(value: T, from_range: (T,T), to_range: (T,T)) -> T
where T: Sub<Output=T> + Add<Output=T> + Div<Output=T> + Mul<Output=T> + Copy {
    to_range.0 + ((to_range.1 - to_range.0) / (from_range.1 - from_range.0)) * (value - from_range.0)
}

#[derive(Copy,Clone,Default)]
struct ScoreInfo {
    score: i32,
    hurdle_medals: (i32,i32,i32),
    archery_medals: (i32,i32,i32),
    skating_medals: (i32,i32,i32),
    diving_medals: (i32,i32,i32),
}

fn calc_score(medals: (i32,i32,i32)) -> i32 {
    3 * medals.0 + medals.1
}

impl ScoreInfo {
    fn from_string(s: String) -> Self {
        let i: Vec<i32> = s.split(" ").map(|x|parse_input!(x, i32)).collect();
        ScoreInfo {
            score: i[0],
            hurdle_medals: (i[1],i[2],i[3]),
            archery_medals: (i[4],i[5],i[6]),
            skating_medals: (i[7],i[8],i[9]),
            diving_medals: (i[10],i[11],i[12]),
        }
    }
}

fn heuristic_game_loop(player_idx: i32, turn: i32) {
    let mut score_infos = [ScoreInfo::default();3];
    for i in 0..3 as usize {
        let mut input_line = String::new();
        io::stdin().read_line(&mut input_line).unwrap();
        let score_info = input_line.trim_matches('\n').to_string();
        score_infos[i] = ScoreInfo::from_string(score_info);
    }
    let games: Vec<(i32,Box<dyn GameManager>)> = vec![
        // UnImplementedGameManager::create_from_input(player_idx),
        // UnImplementedGameManager::create_from_input(player_idx),
        (calc_score(score_infos[player_idx as usize].hurdle_medals), HurdleGameManager::create_from_input(player_idx)),
        (calc_score(score_infos[player_idx as usize].archery_medals), ArcheryGameManager::create_from_input(player_idx)),
        (calc_score(score_infos[player_idx as usize].skating_medals), SkatingGameManager::create_from_input(player_idx)),
        (calc_score(score_infos[player_idx as usize].diving_medals), DivingManager::create_from_input(player_idx)),
    ];

    let mut all_games = AllGamesState::new(games);

    for _ in 0..10 {
        all_games.advance_game_states();
    }

    let command = all_games.get_best_intial_move();
    
    println!("{}", command.to_string());
}

#[derive(Eq, PartialEq, Copy, Clone, Debug)]
enum Command {
    UP,
    RIGHT,
    DOWN,
    LEFT,
}

impl Command {
    fn to_string(&self) -> &str {
        match self {
            Command::UP => "UP",
            Command::RIGHT => "RIGHT",
            Command::DOWN => "DOWN",
            Command::LEFT => "LEFT",
        }
    }

    fn letter(&self) -> char {
        match self {
            Command::UP => 'U',
            Command::RIGHT => 'R',
            Command::DOWN => 'D',
            Command::LEFT => 'L',
        }
    }

    fn index(&self) -> usize {
        match self {
            Command::UP => 0,
            Command::RIGHT => 1,
            Command::DOWN => 2,
            Command::LEFT => 3,
        }
    }

    fn from_index(index: usize) -> Command {
        match index {
            0 => Command::UP,
            1 => Command::RIGHT,
            2 => Command::DOWN,
            3 => Command::LEFT,
            _ => panic!("Unexpected index")
        }
    }

    fn hurdle_moves(&self) -> usize {
        match self {
            Command::UP => 2,
            Command::RIGHT => 3,
            Command::DOWN => 2,
            Command::LEFT => 1,
        }
    }

    fn from_letter(c: char) -> Self {
        match c {
            'U' => Self::UP,
            'R' => Self::RIGHT,
            'D' => Self::DOWN,
            'L' => Self::LEFT,
            _ => panic!("Unrecognised character"),
        }
    }
}

#[derive(Clone, Copy, Default, Debug)]
struct CommandList<T>([T;4]);

impl<T> CommandList<T> {
    fn get_best_action(&self) -> Command
        where T: Ord + Copy {
        zip(COMMANDS, self.0).max_by_key(|x| x.1).unwrap().0
    }

    fn init(value: T) -> Self 
    where T: Copy {
        CommandList([value;4])
    }

    fn new(value: [T;4]) -> Self 
    where  {
        CommandList(value)
    }

    fn map<B, F>(&self, f: F) -> CommandList<B>
    where F: Fn(&T) -> B {
        CommandList([
            f(&self[0]),
            f(&self[1]),
            f(&self[2]),
            f(&self[3]),
        ])
    }

    fn map_with_command<B, F>(&self, f: F) -> CommandList<B>
    where F: Fn(Command, &T) -> B {
        CommandList([
            f(Command::UP, &self[0]),
            f(Command::RIGHT, &self[1]),
            f(Command::DOWN, &self[2]),
            f(Command::LEFT, &self[3]),
        ])
    }

    fn map_mut<F>(&mut self, f: F)
    where F: Fn(&T) -> T {
        for command in COMMANDS {
            self[command] = f(&self[command])
        }
    }

    fn map_mut_with_command<F>(&mut self, f: F)
    where F: Fn(Command, &T) -> T {
        for command in COMMANDS {
            self[command] = f(command, &self[command])
        }
    }

    fn map_mut_in_place<F>(&mut self, f: F)
    where F: Fn(&mut T) {
        for command in COMMANDS {
            f(&mut self[command])
        }
    }

    fn map_mut_in_place_with_command<F>(&mut self, f: F)
    where F: Fn(Command, &mut T) {
        for command in COMMANDS {
            f(command, &mut self[command])
        }
    }

    fn to_string(&self) -> String
    where T: std::fmt::Display {
        format!("UP: {}, RIGHT: {}, DOWN: {}, LEFT: {}", self[0], self[1], self[2], self[3])
    }

    fn normalised(&self) -> CommandList<T>
    where T: Add<Output=T> + std::ops::Div<Output = T> + Copy {
        let total = self.sum();
        CommandList::new([self[0]/total, self[1]/total, self[2]/total, self[3]/total])
    }

    fn sum(&self) -> T
    where T: Add<Output=T> + Copy {
        self[0] + self[1] + self[2] + self[3]
    }

    fn from_commands(x: impl Fn(Command) -> T) -> CommandList<T> {
        Self::new(COMMANDS.map(x))
    }
}

impl CommandList<f32> {
    fn get_best_action_f32(self: CommandList<f32>) -> Command
    {
        zip(COMMANDS, self.0).max_by_key(|x| OrderedFloat(x.1)).unwrap().0
    }

    fn f32_from_option_command(command: Option<Command>) -> CommandList<f32> {
        match command {
            Some(command) => {
                let mut c = CommandList::init(0.);
                c[command] = 1.;
                c
        },
            None => CommandList::init(0.),
        }
    }
}

impl<T> Index<Command> for CommandList<T> {
    type Output = T;

    fn index(&self, index: Command) -> &Self::Output {
        &self.0[index.index()]
    }
}

impl<T> IndexMut<Command> for CommandList<T> {
    fn index_mut(&mut self, index: Command) -> &mut Self::Output {
        &mut self.0[index.index()]
    }
}

impl<T> Index<usize> for CommandList<T> {
    type Output = T;

    fn index(&self, index: usize) -> &Self::Output {
        &self.0[index]
    }
}

impl<T> IndexMut<usize> for CommandList<T> {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output {
        &mut self.0[index]
    }
}


impl<T> Sum for CommandList<T>
where T: Default + Add<Output = T> + Clone + Copy {
    fn sum<I: Iterator<Item = Self>>(iter: I) -> Self {
        let mut count = CommandList::init(T::default());
        for i in iter {
            count = count + i;
        }
        count
    }
}

impl<T> Mul for CommandList<T>
where T: Default + Mul<Output = T> + Clone + Copy {
    type Output=CommandList<T>;

    fn mul(self, rhs: Self) -> Self::Output {
        let a = self;
        let b = rhs;
        CommandList([a[0] * b[0], a[1] * b[1], a[2] * b[2], a[3] * b[3]])
    }
}


impl<T> Add for CommandList<T>
where T: Copy + Add<Output = T> {
    type Output = CommandList<T>;

    fn add(self, rhs: Self) -> Self::Output {
        let a = self;
        let b = rhs;
        CommandList([a[0] + b[0], a[1] + b[1], a[2] + b[2], a[3] + b[3]])
    }
}

fn get_inputs() -> (String,i32,i32,i32,i32,i32,i32,i32) {
    let mut input_line = String::new();
    io::stdin().read_line(&mut input_line).unwrap();
    let inputs = input_line.split(" ").collect::<Vec<_>>();
    (inputs[0].trim().to_string(),
    parse_input!(inputs[1], i32),
    parse_input!(inputs[2], i32),
    parse_input!(inputs[3], i32),
    parse_input!(inputs[4], i32),
    parse_input!(inputs[5], i32),
    parse_input!(inputs[6], i32),
    parse_input!(inputs[7], i32))
}

struct AllGamesState {
    games: Vec<(i32,Box<dyn GameManager>)>,
    initial_turn_done: bool,
}


impl AllGamesState {
    fn advance_game_states(&mut self) {
        let overall_prediction = self.games.iter().map(|(_,x)| x.opponent_turns_prediction()).sum::<CommandList<OpponentTurnsPrediction>>();
        let most_likely_opponent_moves = overall_prediction.map(|x| x.get_most_likely());
        if self.initial_turn_done {
            let best_action = self.games.iter().map(|(_,x)| x.best_moves_given_turn_prediction(most_likely_opponent_moves)).sum::<CommandList<CommandMedalChancePrediction>>();
            for (score,g) in &mut self.games {
                g.advance_states(most_likely_opponent_moves.map_with_command(|command,[b,c]| [best_action[command].prediction.get_best_action_f32(), *b,*c]));
            }
        } else {
            for (score,g) in &mut self.games {
                g.set_initial_state(most_likely_opponent_moves);
            }
            self.initial_turn_done = true;
        }
    }

    fn new(games: Vec<(i32, Box<dyn GameManager>)>) -> Self {
        Self{games, initial_turn_done: false}
    }

    fn get_best_intial_move(&self) -> Command {
        assert!(self.initial_turn_done);
        let v = self.games.iter().map(|(score,x)| x.best_initial_move().prediction.map(|y| y + *score as f32));
        let g = v.fold(CommandList::init(1.), |init, v| init * v);
        g.get_best_action_f32()
    }
}

#[derive(Clone, Copy, Default)]
struct OpponentTurnsPrediction {
    opp_1_command_likelihood: CommandList<f32>,
    opp_2_command_likelihood: CommandList<f32>,
}

impl OpponentTurnsPrediction {
    fn get_most_likely(&self) -> [Command;2] {
        [self.opp_1_command_likelihood.get_best_action_f32(), self.opp_2_command_likelihood.get_best_action_f32()]
    }
}

impl Sum for OpponentTurnsPrediction {
    fn sum<I: Iterator<Item = Self>>(iter: I) -> Self {
        let mut opp_1_command_likelihood = CommandList::init(0.);
        let mut opp_2_command_likelihood = CommandList::init(0.);
        for otp in iter {
            opp_1_command_likelihood = opp_1_command_likelihood + otp.opp_1_command_likelihood;
            opp_2_command_likelihood = opp_1_command_likelihood + otp.opp_2_command_likelihood;
        }
        Self {
            opp_1_command_likelihood,
            opp_2_command_likelihood,
        }
    }
}

impl Add for OpponentTurnsPrediction {
    type Output = OpponentTurnsPrediction;

    fn add(self, rhs: Self) -> Self::Output {
        Self{ 
            opp_1_command_likelihood: self.opp_1_command_likelihood + rhs.opp_1_command_likelihood, 
            opp_2_command_likelihood: self.opp_2_command_likelihood + rhs.opp_2_command_likelihood 
        }
    }
}

#[derive(Clone, Copy, Default)]
struct CommandMedalChancePrediction {
    prediction: CommandList<f32>,
}
impl CommandMedalChancePrediction {
    fn new(prediction: CommandList<f32>) -> Self {
        Self{prediction}
    }
}


impl Add for CommandMedalChancePrediction {
    type Output=CommandMedalChancePrediction;

    fn add(self, rhs: Self) -> Self::Output {
        Self{ prediction: self.prediction + rhs.prediction }
    }
}



trait GameManager {
    fn opponent_turns_prediction(&self) -> CommandList<OpponentTurnsPrediction>;
    fn best_moves_given_turn_prediction(&self, turn_prediction: CommandList<[Command;2]>) -> CommandList<CommandMedalChancePrediction>;
    fn set_initial_state(&mut self, opponent_turns: CommandList<[Command;2]>);
    fn advance_states(&mut self, commands: CommandList<[Command;3]>);
    fn best_initial_move(&self) -> CommandMedalChancePrediction;
}

struct UnImplementedGameManager {}

impl GameManager for UnImplementedGameManager {
    fn opponent_turns_prediction(&self) -> CommandList<OpponentTurnsPrediction> {
        CommandList::init(OpponentTurnsPrediction{ opp_1_command_likelihood: CommandList::init(0.), opp_2_command_likelihood: CommandList::init(0.)})
    }
    fn best_moves_given_turn_prediction(&self, _turn_prediction: CommandList<[Command;2]>) -> CommandList<CommandMedalChancePrediction> {
        CommandList::init(CommandMedalChancePrediction { prediction: CommandList::init(0.) })
    }
    fn best_initial_move(&self) -> CommandMedalChancePrediction {
        CommandMedalChancePrediction { prediction: CommandList::init(0.) }
    }
    fn set_initial_state(&mut self, _opponent_turns: CommandList<[Command;2]>) {}
    fn advance_states(&mut self, _commands: CommandList<[Command;3]>) {}
}

impl UnImplementedGameManager {
    fn create_from_input(_player_idx: i32) -> Box<Self> {
        get_inputs();
        Box::new( Self {} )
    }
}

enum HurdleGameManager {
    Running(String, OneOrFour<HurdleGameState>),
    GameOver(),
}

impl GameManager for HurdleGameManager {
    fn opponent_turns_prediction(&self) -> CommandList<OpponentTurnsPrediction> {
        match self {
            HurdleGameManager::Running(track, states) =>         
            match states {
                OneOrFour::One(state) => CommandList::init(state.get_opponent_predictions(track)),
                OneOrFour::Four(states) => states.map(|x| x.get_opponent_predictions(track)),
            },
            HurdleGameManager::GameOver() => CommandList::default(),
        }
    }

    fn best_moves_given_turn_prediction(&self, _turn_prediction: CommandList<[Command;2]>) -> CommandList<CommandMedalChancePrediction> {
        match self {
            HurdleGameManager::Running(track, states) =>         match states {
                OneOrFour::One(state) => CommandList::init(state.get_best_current_move(track)),
                OneOrFour::Four(states) => states.map(|x| x.get_best_current_move(track)),
            },
            HurdleGameManager::GameOver() => CommandList::default(),
        }
    }

    fn set_initial_state(&mut self, opponent_turns: CommandList<[Command;2]>) {
        match self {
            HurdleGameManager::Running(track, states) => {
                *states = OneOrFour::Four(match states {
                    OneOrFour::One(state) => opponent_turns.map_with_command(
                        |command, [b,c]| {
                            let mut s = state.clone();
                            s.apply([command, *b, *c], track);
                            s
                        }
                    ),
                    OneOrFour::Four(_) => panic!("Must set initial state first"),
                });
            },
            HurdleGameManager::GameOver() => (),
        }
    }

    fn advance_states(&mut self, commands: CommandList<[Command;3]>) {
        match self {
            HurdleGameManager::Running(track, states) =>         match states {
                OneOrFour::One(_) => panic!("Can't be done until initial state set"),
                OneOrFour::Four(mut states) => states.map_mut_in_place_with_command(|command, x| x.apply(commands[command], track)),
            },
            HurdleGameManager::GameOver() => (),
        }
    }

    fn best_initial_move(&self) -> CommandMedalChancePrediction {
        match self {
            HurdleGameManager::Running(track, states) => match states {
                OneOrFour::One(_) => panic!("Must compute once to get a prediction of good outcomes"),
                OneOrFour::Four(states) => {
                    let prediction = states.map(|x| x.get_medal_chance_prediction(track));
                    CommandMedalChancePrediction::new(prediction)
                },
            },
            HurdleGameManager::GameOver() => CommandMedalChancePrediction::default(),
        }
    }
}

impl HurdleGameManager {
    fn create_from_input(player_idx: i32) -> Box<Self> {
        let (track, reg_0, reg_1,reg_2,reg_3,reg_4,reg_5,_reg_6) = get_inputs();
        if track == "GAME_OVER" {
            Box::new(Self::GameOver())
        } else {
            let (player, opp_1, opp_2) = match player_idx {
                0 => (HurdlePlayerState::new(reg_0,reg_3),HurdlePlayerState::new(reg_1,reg_4),HurdlePlayerState::new(reg_2,reg_5)),
                1 => (HurdlePlayerState::new(reg_1,reg_4),HurdlePlayerState::new(reg_0,reg_3),HurdlePlayerState::new(reg_2,reg_5)),
                2 => (HurdlePlayerState::new(reg_2,reg_5),HurdlePlayerState::new(reg_0,reg_3),HurdlePlayerState::new(reg_1,reg_4)),
                _ => panic!("Unexpected player_idx"),
            };
            Box::new(Self::Running(track, OneOrFour::One(HurdleGameState{ player, opp_1, opp_2, finished: false })))
        }
    }
}

#[derive(Clone, Copy)]
struct HurdleGameState {
    player: HurdlePlayerState,
    opp_1: HurdlePlayerState,
    opp_2: HurdlePlayerState,
    finished: bool,
}

impl HurdleGameState {
    fn get_opponent_predictions(&self, track: &str) -> OpponentTurnsPrediction {
        if self.finished {
            OpponentTurnsPrediction {
                opp_1_command_likelihood: CommandList::init(0.), 
                opp_2_command_likelihood: CommandList::init(0.) 
            }
        } else {
            OpponentTurnsPrediction {
                opp_1_command_likelihood: CommandList::f32_from_option_command(self.opp_1.best_move(track)), 
                opp_2_command_likelihood: CommandList::f32_from_option_command(self.opp_2.best_move(track)) 
            }
        }
    }

    fn get_best_current_move(&self, track: &str) -> CommandMedalChancePrediction {
        if self.finished {
            CommandMedalChancePrediction {
                prediction: CommandList::init(0.)
            }
        } else {
            CommandMedalChancePrediction {
                prediction: CommandList::f32_from_option_command(self.player.best_move(track))
            }
        }
    }

    fn apply(&mut self, commands: [Command;3], track: &str) {
        if self.finished {
            return;
        }
        let finish_pos = [self.player,self.opp_1,self.opp_2].iter().filter(|x| x.has_finished()).count() as i32;
        self.player.apply(commands[0], track, finish_pos);
        self.opp_1.apply(commands[1], track, finish_pos);
        self.opp_2.apply(commands[2], track, finish_pos);
        if [self.player,self.opp_1,self.opp_2].iter().filter(|x| x.has_finished()).count() >= 2 {
            self.finished = true;
        }
    }

    fn get_medal_chance_prediction(&self, track: &str) -> f32 {
        match self.player {
            HurdlePlayerState::Running(pos, stun_timer) => {
                let pos = pos - (stun_timer * 2);
                let max = if self.opp_1.has_finished() || self.opp_2.has_finished() {
                    1.
                } else {
                    3.
                };
                let (first, last) = if self.opp_1.get_distance(track) > self.opp_2.get_distance(track) {
                    (self.opp_1, self.opp_2)
                } else {
                    (self.opp_2, self.opp_1)
                };
                let max_distance = 20;
                // from 0 to 1, 0.5 is player is at exact same position up to 10 places either side
                let modifier = if pos < last.get_distance(track) {
                    pos - last.get_distance(track)
                } else {
                    pos - first.get_distance(track)
                }.min(max_distance).max(-max_distance) as f32 / (max_distance as f32);
                max * modifier
            },
            HurdlePlayerState::Finished(value) => if value == 0 {
                return 3.
            } else if value == 1 {
                return 1.
            } else {
                return 0.
            },
        }
    }
}

#[derive(Clone, Copy)]
enum HurdlePlayerState {
    Running(i32,i32),
    Finished(i32),
}

impl HurdlePlayerState {
    fn new(position: i32, stun_timer: i32) -> Self { Self::Running(position, stun_timer) }

    fn best_move(&self, track: &str) -> Option<Command> {
        match self {
            HurdlePlayerState::Running(position, stun_timer) => {
                if *stun_timer > 0 { return None }
                for (i,c) in track[1 + *position as usize..].chars().take(3).enumerate() {
                    if c == '#' {
                        if i == 0 {
                            return Some(Command::UP);
                        } else if i == 1 {
                            return Some(Command::LEFT);
                        } else if i == 2 {
                            return Some(Command::DOWN);
                        }
                    }
                }
                Some(Command::RIGHT)
            }
            HurdlePlayerState::Finished(_) => return None,
        }
    }

    fn apply(&mut self, command: Command, track: &str, finish_pos: i32) {
        // Check if we jump over hurdle
        match self {
            HurdlePlayerState::Running(position, stun_timer) => 
            {
                if *stun_timer > 0 {
                    *stun_timer -= 1;
                } else {
                    let moves = command.hurdle_moves();
                    let start_pos = 1 + *position as usize;
                    for (i,c) in track[start_pos..].chars().take(moves).enumerate() {
                        if c == '#' {
                            if command != Command::UP || i != 0 {
                                *stun_timer = 3;
                                *position = (start_pos + i) as i32;
                            }
                        }
                    }
                    let new_pos = start_pos + moves - 1;
                    if new_pos >= track.len() {
                        *self = HurdlePlayerState::Finished(finish_pos);
                    } else {
                        *position = new_pos as i32;
                    }
                }
            },
            HurdlePlayerState::Finished(_) => (),
        }
    }

    fn has_finished(&self) -> bool {
        match self {
            HurdlePlayerState::Running(_, _) => false,
            HurdlePlayerState::Finished(_) => true,
        }
    }

    fn get_distance(&self, track: &str) -> i32 {
        match self {
            HurdlePlayerState::Running(pos, stun_timer) => pos - (stun_timer * 2),
            HurdlePlayerState::Finished(_) => return track.len() as i32,
        }
    }
}

enum ArcheryGameManager {
    Running(String, OneOrFour<ArcheryGameState>),
    GameOver(),
}

impl GameManager for ArcheryGameManager {
    fn opponent_turns_prediction(&self) -> CommandList<OpponentTurnsPrediction> {
        match self {
            ArcheryGameManager::Running(wind, states) => {
                if wind.len() > 0 {
                    let wind_strength = parse_input!(wind[0..1], i32);
                    match states {
                                OneOrFour::One(state) => CommandList::init(state.get_opponent_predictions(wind_strength)),
                                OneOrFour::Four(states) => states.map(|x| x.get_opponent_predictions(wind_strength)),
                            }
                } else {
                    CommandList::default()
                }
            },
            ArcheryGameManager::GameOver() => CommandList::default(),
        }
    }

    fn best_moves_given_turn_prediction(&self, _turn_prediction: CommandList<[Command;2]>) -> CommandList<CommandMedalChancePrediction> {
        match self {
            ArcheryGameManager::Running(wind, states) => {
                if wind.is_empty() { 
                    CommandList::default()
                } else {
                    let wind_strength = parse_input!(wind[0..1], i32);
                    match states {
                        OneOrFour::One(state) => CommandList::init(state.get_best_current_move(wind_strength)),
                        OneOrFour::Four(states) => states.map(|x| x.get_best_current_move(wind_strength)),
                    }
                }
            },
            ArcheryGameManager::GameOver() => CommandList::default(),
        }
    }

    fn set_initial_state(&mut self, opponent_turns: CommandList<[Command;2]>) {
        match self {
            ArcheryGameManager::Running(wind, states) => {
                if wind.is_empty() { return; }
                let wind_strength = parse_input!(wind[0..1], i32);
                *states = match states {
                    OneOrFour::One(state) => OneOrFour::Four(opponent_turns.map_with_command(|a,[b,c]| state.apply_commands([a,*b,*c], wind_strength))),
                    OneOrFour::Four(_) => panic!("Can only be done on uninitialised state"),
                };
                wind.remove(0);
            }
            ArcheryGameManager::GameOver() => (),
        }
    }

    fn advance_states(&mut self, commands: CommandList<[Command;3]>) {
        match self {
            ArcheryGameManager::Running(wind, states) => {
                if wind.is_empty() { return; }
                let wind_strength = parse_input!(wind[0..1], i32);
                match states {
                        OneOrFour::One(_) => panic!("Must init states first"),
                        OneOrFour::Four(states) => states.map_mut_in_place_with_command(|command, x| x.apply_in_place(commands[command], wind_strength)),
                    }
                wind.remove(0);
            },
            ArcheryGameManager::GameOver() => (),
        }
    }

    fn best_initial_move(&self) -> CommandMedalChancePrediction {
        match self {
            ArcheryGameManager::Running(wind, states) => match states {
                OneOrFour::One(_) => panic!("Must inits states first"),
                OneOrFour::Four(states) => {
                    let prediction = states.map(|x| x.get_medal_value());
                    CommandMedalChancePrediction::new(prediction)
                },
            },
            ArcheryGameManager::GameOver() => CommandMedalChancePrediction::default(),
        }
    }
}

impl ArcheryGameManager {
    fn create_from_input(player_idx: i32) -> Box<Self> {
        let (wind, reg_0, reg_1,reg_2,reg_3,reg_4,reg_5,_reg_6) = get_inputs();
        if wind == "GAME_OVER" {
            Box::new(Self::GameOver())
        } else {
            let (player, opp_1, opp_2) = match player_idx {
                0 => (ArcheryPlayerState::new(reg_0,reg_1),ArcheryPlayerState::new(reg_2,reg_3),ArcheryPlayerState::new(reg_4,reg_5)),
                1 => (ArcheryPlayerState::new(reg_2,reg_3),ArcheryPlayerState::new(reg_0,reg_1),ArcheryPlayerState::new(reg_4,reg_5)),
                2 => (ArcheryPlayerState::new(reg_4,reg_5),ArcheryPlayerState::new(reg_0,reg_1),ArcheryPlayerState::new(reg_2,reg_3)),
                _ => panic!("Unexpected player_idx"),
            };
            Box::new(Self::Running(wind, OneOrFour::One(ArcheryGameState{ player, opp_1, opp_2 , diagnol_distance: euclidean_distance_i32(ARCHERY_MAX,ARCHERY_MAX) })))
        }
    }
}

#[derive(Clone, Copy, Debug)]
struct ArcheryGameState {
    player: ArcheryPlayerState,
    opp_1: ArcheryPlayerState,
    opp_2: ArcheryPlayerState,
    diagnol_distance: f32,
}

impl ArcheryGameState {
    fn get_opponent_predictions(&self, wind_strength: i32) -> OpponentTurnsPrediction {
        OpponentTurnsPrediction {
            opp_1_command_likelihood: self.opp_1.get_best_moves(self.diagnol_distance, wind_strength), 
            opp_2_command_likelihood: self.opp_2.get_best_moves(self.diagnol_distance, wind_strength),
        }
    }

    fn get_best_current_move(&self, wind_strength: i32) -> CommandMedalChancePrediction {
        let l = self.player.get_best_moves(self.diagnol_distance, wind_strength);
        CommandMedalChancePrediction {
            prediction: l
        }
    }

    fn apply_commands(&self, commands: [Command; 3], wind_strength: i32) -> Self {
        Self { 
            player: self.player.move_by_wind(wind_strength, commands[0]), 
            opp_1: self.opp_1.move_by_wind(wind_strength, commands[1]), 
            opp_2: self.opp_2.move_by_wind(wind_strength, commands[2]), 
            diagnol_distance: self.diagnol_distance 
        }
    }

    fn apply_in_place(&mut self, commands: [Command; 3], wind_strength: i32) {
        self.player.apply_wind(wind_strength, commands[0]);
        self.opp_1.apply_wind(wind_strength, commands[1]);
        self.opp_2.apply_wind(wind_strength, commands[2]);
    }

    // Values range from 0.0 when at max distance, to 1.0 when overtaking the furthest AI, to 3.0 when closer than the closest AI
    fn get_medal_value(&self) -> f32 {
        let player_dist = self.player.get_distance();
        let opp_1_dist = self.opp_1.get_distance();
        let opp_2_dist = self.opp_2.get_distance();
        let (best,worst) = if opp_1_dist > opp_2_dist { (opp_2_dist, opp_1_dist) } else { (opp_1_dist, opp_2_dist)};
        if player_dist <= best {
            3. - map_from_range_to_range(player_dist, (0., best), (0.,1.))
        } else if player_dist <= worst {
            // Range from 2.0 to 1.0 depending on distance between best and worst
            // if at worst, then 1.0 if almost best, then 2.0
            // best < player_dist && player_dist <= worst <= MAX
            2. - map_from_range_to_range(player_dist, (best, worst), (0.,1.))
        } else {
            // Range from 0.5 to 0.0 depending on distance between worst and max distance
            0.5 - map_from_range_to_range(player_dist, (worst, self.diagnol_distance), (0.,0.5))
        }
    }
}

#[derive(Clone, Copy, Debug)]
struct ArcheryPlayerState {
    x: i32,
    y: i32,
}

impl ArcheryPlayerState {
    fn new(x: i32, y: i32) -> ArcheryPlayerState {
        Self{x,y}
    }

    fn move_by_wind(&self, wind_strength: i32, x: Command) -> Self {
        match x {            
            Command::UP => Self{ x: self.x, y: (self.y - wind_strength).max(-ARCHERY_MAX)},
            Command::RIGHT => Self{ x: (self.x + wind_strength).min(ARCHERY_MAX), y: self.y},  
            Command::DOWN => Self{ x: self.x, y: (self.y + wind_strength).min(ARCHERY_MAX)},
            Command::LEFT =>  Self{ x: (self.x - wind_strength).max(-ARCHERY_MAX), y: self.y},
        }
    }

    fn apply_wind(&mut self, wind_strength: i32, command: Command) {
        match command {
            Command::UP => self.y = (self.y - wind_strength).max(-ARCHERY_MAX),
            Command::RIGHT => self.x = (self.x + wind_strength).min(ARCHERY_MAX),
            Command::DOWN => self.y = (self.y + wind_strength).min(ARCHERY_MAX),
            Command::LEFT =>  self.x = (self.x - wind_strength).max(-ARCHERY_MAX),
        }
    }

    fn get_distance_after_movement(&self, wind_strength: i32, x: Command) -> f32 {
        self.move_by_wind(wind_strength, x).get_distance()
    }

    fn get_distance(&self) -> f32 {
        euclidean_distance_i32(self.x, self.y)
    }

    fn get_best_moves(&self, diagnol_distance: f32, wind_strength: i32) -> CommandList<f32> {
        CommandList::from_commands(|x| {
            let v = diagnol_distance - self.get_distance_after_movement(wind_strength, x);
            v
        }).normalised()
    }
}

enum SkatingGameManager {
    Start(RiskOrder, SkatingGameState),
    End(CommandList<SkatingGameState>),
    GameOver(),
}

impl GameManager for SkatingGameManager {
    fn opponent_turns_prediction(&self) -> CommandList<OpponentTurnsPrediction> {
        match self {
            SkatingGameManager::Start(risk, state) => state.get_opponent_best_moves(risk),
            SkatingGameManager::End(_) => CommandList::default(),
            SkatingGameManager::GameOver() => CommandList::default(),
        }
    }

    fn best_moves_given_turn_prediction(&self, turn_prediction: CommandList<[Command;2]>) -> CommandList<CommandMedalChancePrediction> {
        // Skating can only look one ahead, so no prediction is possible.
        CommandList::default()
    }

    fn set_initial_state(&mut self, opponent_turns: CommandList<[Command;2]>) {
        match self {
            SkatingGameManager::Start(risk_order, state) => {
                *self = SkatingGameManager::End(CommandList::from_commands(|c| state.clone().apply_commands([c,opponent_turns[c][0],opponent_turns[c][1]], risk_order)))
            },
            SkatingGameManager::End(_) => panic!("Can only initialise"),
            SkatingGameManager::GameOver() => (),
        }
    }

    fn advance_states(&mut self, commands: CommandList<[Command;3]>) {
        match self {
            SkatingGameManager::Start(_, _) => panic!("Must ensure initialised first"),
            SkatingGameManager::End(_) => (),
            SkatingGameManager::GameOver() => (),
        }
    }

    fn best_initial_move(&self) -> CommandMedalChancePrediction {
        match self {
            SkatingGameManager::Start(_, _) => panic!("Must ensure initialised first"),
            SkatingGameManager::End(state) => CommandMedalChancePrediction::new(state.map(|s| s.get_medal_value())),
            SkatingGameManager::GameOver() => CommandMedalChancePrediction::default(),
        }
    }
}

impl SkatingGameManager {
    fn create_from_input(player_idx: i32) -> Box<Self> {
        let (gpu, reg_0, reg_1,reg_2,reg_3,reg_4,reg_5,reg_6) = get_inputs();
        if gpu == "GAME_OVER" {
            Box::new(Self::GameOver())
        } else {
            let risk = RiskOrder::new(gpu);
            let (player, opp_1, opp_2) = match player_idx {
                0 => (SkatingPlayerState::new(reg_0,reg_3),SkatingPlayerState::new(reg_1,reg_4),SkatingPlayerState::new(reg_2,reg_5)),
                1 => (SkatingPlayerState::new(reg_1,reg_4),SkatingPlayerState::new(reg_0,reg_3),SkatingPlayerState::new(reg_2,reg_5)),
                2 => (SkatingPlayerState::new(reg_2,reg_5),SkatingPlayerState::new(reg_0,reg_3),SkatingPlayerState::new(reg_1,reg_4)),
                _ => panic!("Unexpected player_idx"),
            };
            Box::new(Self::Start(risk, SkatingGameState{ player, opp_1, opp_2, turns_left: reg_6 }))
        }
    }
}

struct RiskOrder(CommandList<(i32,i32)>);

impl RiskOrder {
    fn new(gpu: String) -> Self {
        let mut chars = gpu.chars();
        let mut c_list = CommandList::default();
        c_list[Command::from_letter(chars.next().unwrap())] = (1,-1);
        c_list[Command::from_letter(chars.next().unwrap())] = (2,0);
        c_list[Command::from_letter(chars.next().unwrap())] = (2,1);
        c_list[Command::from_letter(chars.next().unwrap())] = (3,2);
        RiskOrder(c_list)
    }
}

#[derive(Clone)]
struct SkatingGameState {
    player: SkatingPlayerState,
    opp_1: SkatingPlayerState,
    opp_2: SkatingPlayerState,
    turns_left: i32,
}

impl SkatingGameState {
    fn apply_commands(self, c: [Command; 3], risk_order: &RiskOrder) -> SkatingGameState {
        let mut player = self.player.apply_commands(c[0], risk_order);
        let mut opp_1 = self.opp_1.apply_commands(c[1], risk_order);
        let mut opp_2 = self.opp_2.apply_commands(c[2], risk_order);
        // If any players are on the same spot increase their risk by two
        player.add_risk_if_spaces([opp_1.spaces_travelled % 10, opp_2.spaces_travelled % 10]);
        opp_1.add_risk_if_spaces([player.spaces_travelled % 10, opp_2.spaces_travelled % 10]);
        opp_2.add_risk_if_spaces([player.spaces_travelled % 10, opp_1.spaces_travelled % 10]);

        SkatingGameState { player, opp_1, opp_2, turns_left: self.turns_left - 1 }
    }

    fn get_opponent_best_moves(&self, risk: &RiskOrder) -> CommandList<OpponentTurnsPrediction> {
        CommandList::init(OpponentTurnsPrediction{ 
            opp_1_command_likelihood: self.opp_1.get_best_moves(risk), 
            opp_2_command_likelihood: self.opp_2.get_best_moves(risk)
        })
    }

    fn get_medal_value(&self) -> f32 {
        let modifier = 1. - map_from_range_to_range(15. - self.turns_left as f32, (0., 15.), (0., 1.));
        let estimated_track_distance_left = self.turns_left as f32 * 2.5;
        let player_dist = self.player.estimated_distance(self.turns_left);
        let opp_1_dist = self.opp_1.estimated_distance(self.turns_left);
        let opp_2_dist = self.opp_2.estimated_distance(self.turns_left);
        let (best, worst) = if opp_1_dist > opp_2_dist { (opp_1_dist, opp_2_dist)} else {(opp_2_dist,opp_1_dist)};
        modifier * if self.turns_left == 0 {
            if player_dist >= best {
                3.
            } else {
                if player_dist >= worst {
                    1.
                } else {
                    0.
                }
            }
        } else {
            if player_dist >= best {
                map_from_range_to_range(player_dist.min(estimated_track_distance_left), (best,best + estimated_track_distance_left), (2.,3.))
            } else {
                if player_dist >= worst {
                    map_from_range_to_range(player_dist, (worst,best), (1., 2.))
                } else {
                    map_from_range_to_range(player_dist, (worst - estimated_track_distance_left,worst), (0., 1.))
                }
            }
        }
    }
}

#[derive(Clone,Copy)]
struct SkatingPlayerState {
    spaces_travelled: i32,
    risk_stun: RiskStun,
}

#[derive(Clone,Copy)]
enum RiskStun {
    Risk(i32),
    Stun(i32),
}

impl RiskStun {
    fn from_i32(i: i32) -> Self {
        if i < 0 {
            Self::Stun(-i)
        } else {
            Self::Risk(i)
        }
    }
}

impl SkatingPlayerState {
    fn new(spaces_travelled: i32, risk_stun: i32) -> Self { Self { spaces_travelled, risk_stun: RiskStun::from_i32(risk_stun) } }

    fn apply_commands(self, c: Command, risk_order: &RiskOrder) -> SkatingPlayerState {
        let (movement, risk);
        match self.risk_stun {
            RiskStun::Risk(s_risk) => {
                let (m, r) = risk_order.0[c];
                let new_risk = s_risk + r;
                if new_risk >= 5 {
                    risk = RiskStun::Stun(2);
                } else {
                    risk = RiskStun::Risk(new_risk.max(0));
                }
                movement = m;
    
            },
            RiskStun::Stun(stun) => {
                if stun == 0 {
                    (movement, risk) = (0,RiskStun::Risk(0))
                } else {
                    (movement, risk) = (0,RiskStun::Stun(stun-1))
                }
            },
        }
        Self { spaces_travelled: self.spaces_travelled + movement, risk_stun: risk }
    }

    fn get_best_moves(&self, risk: &RiskOrder) -> CommandList<f32> {
        match self.risk_stun {
            RiskStun::Risk(r) => CommandList::from_commands(|c| {       
                let (movement, risk) = risk.0[c];
                let new_risk = risk + r;
                // being stunned should be a penalty of about 3.5
                movement as f32 - map_from_range_to_range(new_risk as f32, (-1.,7.), (0.,4.))
           }).normalised(),
            RiskStun::Stun(_) => CommandList::default(),
        }
    }

    fn add_risk_if_spaces(&mut self, others: [i32; 2]) {
        if others.contains(&(self.spaces_travelled % 10)) {
            match self.risk_stun {
                RiskStun::Risk(i) => {
                    let new_risk = i + 2;
                    if new_risk >= 5 {
                        self.risk_stun = RiskStun::Stun(2)
                    } else {
                        self.risk_stun = RiskStun::Risk(new_risk)
                    }
                },
                RiskStun::Stun(_) => (),
            }
        }
    }

    fn estimated_distance(&self, turns_left: i32) -> f32 {
        match self.risk_stun {
            RiskStun::Risk(r) => self.spaces_travelled as f32,
            RiskStun::Stun(s) => {
                let s = if turns_left < s { turns_left } else { s };
                self.spaces_travelled as f32 - (s as f32 * 2.5)
            },
        }
    }
}


enum DivingManager {
    GameOver,
    Init(DivingGameState, String),
    Running(CommandList<DivingGameState>, String),
    Finished(CommandList<DivingGameState>),
}

impl GameManager for DivingManager {
    fn opponent_turns_prediction(&self) -> CommandList<OpponentTurnsPrediction> {
        match self {
            DivingManager::GameOver => CommandList::default(),
            DivingManager::Init(_, dive_goal) | DivingManager::Running(_, dive_goal) => {
                let c = Command::from_letter(dive_goal.chars().next().unwrap());
                CommandList::init(OpponentTurnsPrediction{
                    opp_1_command_likelihood: CommandList::f32_from_option_command(Some(c)), 
                    opp_2_command_likelihood: CommandList::f32_from_option_command(Some(c))
                })
            }
            DivingManager::Finished(_) => CommandList::default(),
        }
    }

    fn best_moves_given_turn_prediction(&self, _turn_prediction: CommandList<[Command;2]>) -> CommandList<CommandMedalChancePrediction> {
        match self {
            DivingManager::GameOver => CommandList::default(),
            DivingManager::Init(_, dive_goal) | DivingManager::Running(_, dive_goal) => {
                let c = Command::from_letter(dive_goal.chars().next().unwrap());
                CommandList::init(CommandMedalChancePrediction::new(CommandList::f32_from_option_command(Some(c))))
            }
            DivingManager::Finished(_) => CommandList::default(),
        }
    }

    fn set_initial_state(&mut self, opponent_turns: CommandList<[Command;2]>) {
        match self {
            DivingManager::GameOver => (),
            DivingManager::Init(state, dive_goal) => {
                let desired_command = Command::from_letter(dive_goal.chars().next().unwrap());
                let new_states = CommandList::from_commands(|c| state.apply_commands([c,opponent_turns[c][0],opponent_turns[c][1]], desired_command));
                if dive_goal.len() == 1 {
                    *self = Self::Finished(new_states)
                } else {
                    *self = Self::Running(new_states, dive_goal[1..].to_string());
                }
            },
            DivingManager::Running(_, _) => panic!("Must init first"),
            DivingManager::Finished(_) => panic!("Must init first"),
        }
    }

    fn advance_states(&mut self, commands: CommandList<[Command;3]>) {
        match self {
            DivingManager::GameOver => (),
            DivingManager::Init(state, dive_goal) => panic!("Can only init once"),
            DivingManager::Running(states, dive_goal) => {
                let desired_command = Command::from_letter(dive_goal.remove(0));
                states.map_mut_in_place_with_command(|c, s| s.apply_commands_in_place(commands[c],desired_command));
                if dive_goal.len() == 0 {
                    *self = DivingManager::Finished(*states);
                }
            },
            DivingManager::Finished(_) => (),
        }   
    }

    fn best_initial_move(&self) -> CommandMedalChancePrediction {
        match self {
            DivingManager::GameOver => CommandMedalChancePrediction::default(),
            DivingManager::Init(_, _) => panic!("Must have inited"),
            DivingManager::Running(states, string) => CommandMedalChancePrediction::new(states.map(|s| s.get_player_medals(string.len() as i32))),
            DivingManager::Finished(states) => CommandMedalChancePrediction::new(states.map(|s| s.get_player_medals(0))),
        }
    }
}

impl DivingManager {
    fn create_from_input(player_idx: i32) -> Box<Self> {
        let (gpu, reg_0, reg_1,reg_2,reg_3,reg_4,reg_5,reg_6) = get_inputs();
        if gpu == "GAME_OVER" {
            Box::new(Self::GameOver)
        } else {
            let (player, opp_1, opp_2) = match player_idx {
                0 => (DivingPlayerState::new(reg_0,reg_3),DivingPlayerState::new(reg_1,reg_4),DivingPlayerState::new(reg_2,reg_5)),
                1 => (DivingPlayerState::new(reg_1,reg_4),DivingPlayerState::new(reg_0,reg_3),DivingPlayerState::new(reg_2,reg_5)),
                2 => (DivingPlayerState::new(reg_2,reg_5),DivingPlayerState::new(reg_0,reg_3),DivingPlayerState::new(reg_1,reg_4)),
                _ => panic!("Unexpected player_idx"),
            };
            Box::new(Self::Init(DivingGameState{ player, opp_1, opp_2, }, gpu))
        }
    }

}

#[derive(Copy,Clone,Debug)]
struct DivingGameState {
    player: DivingPlayerState,
    opp_1: DivingPlayerState,
    opp_2: DivingPlayerState,
}

impl DivingGameState {
    fn apply_commands(self, c: [Command; 3], desired_command: Command) -> Self {
        let player = self.player.apply_command(c[0], desired_command);
        let opp_1 = self.opp_1.apply_command(c[1], desired_command);
        let opp_2 = self.opp_2.apply_command(c[2], desired_command);
        Self {
            player,
            opp_1,
            opp_2,
        }
    }

    fn apply_commands_in_place(&mut self, commands: [Command; 3], desired_command: Command) {
        self.player.apply_command_in_place(commands[0], desired_command);
        self.opp_1.apply_command_in_place(commands[1], desired_command);
        self.opp_2.apply_command_in_place(commands[2], desired_command);
    }

    fn get_player_medals(&self, remaing_turns: i32) -> f32 {
        let player = self.player.points as f32;
        let opp_1 = self.opp_1.points as f32;
        let opp_2 = self.opp_2.points as f32;
        let (best, worst) = if opp_1 > opp_2 { (opp_1, opp_2)} else {(opp_2,opp_1)};
        if player >= best {
            map_from_range_to_range(player.min(best + 10.), (best, best + 20.), (2., 3.))
        } else {
            if player >= worst {
                map_from_range_to_range(player, (worst, best), (1.,2.))
            } else {
                map_from_range_to_range(player.max(worst - 10.), (worst - 10.,worst), (0.,1.))
            }
        }
    }
}

#[derive(Copy,Clone,Debug)]
struct DivingPlayerState {
    points: i32,
    combo: i32,
}

impl DivingPlayerState {
    fn new(points: i32, combo: i32) -> Self { Self { points, combo } }

    fn apply_command(&self, c: Command, desired_command: Command) -> DivingPlayerState {
        if c == desired_command {
            DivingPlayerState {
                points: self.points + self.combo,
                combo: self.combo + 1,
            }
        } else {
            DivingPlayerState {
                points: self.points,
                combo: 1,
            }
        }
    }

    fn apply_command_in_place(&mut self, command: Command, desired_command: Command) {
        if command == desired_command {
            self.points += self.combo;
            self.combo += 1;
        } else {
            self.combo = 1;
        }
    }
}