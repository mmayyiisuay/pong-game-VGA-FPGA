library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MAIN is
	port (
		CLOCK : in std_logic;
		HSYNC : out std_logic;
		VSYNC : out std_logic;
		RED : out std_logic;
		GREEN : out std_logic;
		BLUE : out std_logic;

		P1_LEFT : in std_logic;
		P1_READY : in std_logic;
		P1_RIGH
		T : in std_logic;
		P2_LEFT : in std_logic;
		P2_READY : in std_logic;
		P2_RIGHT : in std_logic
	);
end MAIN;

architecture Behavioral of MAIN is
	signal x : natural range 0 to 635 := 0;
	signal y : natural range 0 to 525 := 0;

	constant X_VISIBLE_AREA : natural := 508;
	constant X_FRONT_PORCH : natural := 13;
	constant X_SYNC_PULSE : natural := 76;
	constant X_BACK_PORCH : natural := 38;
	constant X_WHOLE_LINE : natural := 635;

	constant Y_VISIBLE_AREA : natural := 480;
	constant Y_FRONT_PORCH : natural := 10;
	constant Y_SYNC_PULSE : natural := 2;
	constant Y_BACK_PORCH : natural := 33;
	constant Y_WHOLE_FRAME : natural := 525;

	constant RIGHT_BORDER : natural := X_WHOLE_LINE - X_FRONT_PORCH + 2;
	constant LEFT_BORDER : natural := X_SYNC_PULSE + X_BACK_PORCH + 1;
	constant DOWN_BORDER : natural := Y_WHOLE_FRAME - Y_FRONT_PORCH + 1;
	constant UP_BORDER : natural := Y_SYNC_PULSE + Y_BACK_PORCH + 1;
	constant GAME_WIDTH : natural := RIGHT_BORDER - LEFT_BORDER;
	constant GAME_HEIGHT : natural := DOWN_BORDER - UP_BORDER;

	type t_rectangle is record
		x : integer range -10 to GAME_WIDTH;
		y : integer range -10 to GAME_HEIGHT;
		dx : integer range -10 to 10;
		dy : integer range -10 to 10;
		w : natural range 0 to 100;
		h : natural range 0 to 100;
		e : boolean;
	end record;

	type t_color is record
		r : std_logic;
		g : std_logic;
		b : std_logic;
	end record;

	type t_colors is record
		color1 : t_color;
		color2 : t_color;
	end record;

	type t_brick is record
		state : natural range 0 to 2;
	end record;

	constant color_black : t_colors := (
		color1 => ( r => '0', g => '0', b => '0' ),
		color2 => ( r => '0', g => '0', b => '0' )
	);
	constant color_white : t_colors := (
		color1 => ( r => '1', g => '1', b => '1' ),
		color2 => ( r => '1', g => '1', b => '1' )
	);
	constant color_red : t_colors := (
		color1 => ( r => '1', g => '0', b => '0' ),
		color2 => ( r => '1', g => '0', b => '0' )
	);
	constant color_orange : t_colors := (
		color1 => ( r => '1', g => '1', b => '0' ),
		color2 => ( r => '1', g => '0', b => '0' )
	);
	constant color_yellow : t_colors := (
		color1 => ( r => '1', g => '1', b => '0' ),
		color2 => ( r => '1', g => '1', b => '0' )
	);
	constant color_lime : t_colors := (
		color1 => ( r => '1', g => '1', b => '0' ),
		color2 => ( r => '0', g => '1', b => '0' )
	);
	constant color_green : t_colors := (
		color1 => ( r => '0', g => '1', b => '0' ),
		color2 => ( r => '0', g => '1', b => '0' )
	);
	constant color_sky : t_colors := (
		color1 => ( r => '0', g => '1', b => '1' ),
		color2 => ( r => '0', g => '1', b => '0' )
	);
	constant color_cyan : t_colors := (
		color1 => ( r => '0', g => '1', b => '1' ),
		color2 => ( r => '0', g => '1', b => '1' )
	);
	constant color_teal : t_colors := (
		color1 => ( r => '0', g => '1', b => '1' ),
		color2 => ( r => '0', g => '0', b => '1' )
	);
	constant color_blue : t_colors := (
		color1 => ( r => '0', g => '0', b => '1' ),
		color2 => ( r => '0', g => '0', b => '1' )
	);
	constant color_purple : t_colors := (
		color1 => ( r => '1', g => '0', b => '1' ),
		color2 => ( r => '0', g => '0', b => '1' )
	);
	constant color_magenta : t_colors := (
		color1 => ( r => '1', g => '0', b => '1' ),
		color2 => ( r => '1', g => '0', b => '1' )
	);
	constant color_pink : t_colors := (
		color1 => ( r => '1', g => '0', b => '1' ),
		color2 => ( r => '1', g => '0', b => '0' )
	);
begin

	process (CLOCK)
		-- Function convert std_logic to integer
		impure function to_integer (
			s : std_logic) return natural is
		begin
			if s = '1' then
				return 1;
			end if;
			return 0;
		end function;

		-- Function for clamping x to range a and b
		impure function clamp (
			x : integer;
			a : integer;
			b : integer) return natural is
		begin
			if x <= a + 1 then
				return a + 1;
			end if;
			if x >= b then
				return b;
			end if;
			return x;
		end function;

		impure function absolute (
			a : integer) return integer is
		begin
			if a > 0 then
				return a;
			end if;
			if a < 0 then
				return 0 - a;
			end if;
			return 0;
		end function;

		impure function intersection (
			b1: t_rectangle;
			b2: t_rectangle) return boolean is
		begin
			if b1.x > b2.x + b2.w or b2.x > b1.x + b1.w or
				b1.y > b2.y + b2.h or b2.y > b1.y + b1.h then
				return false;
			end if;
			return true;
		end function;

		-- Function for bouncing
		impure function bounce (
			box1 : t_rectangle;
			box2 : t_rectangle) return t_rectangle is
			variable box : t_rectangle;
		begin
			box := box1;
			if intersection(box1, box2) then
				if box1.x <= box2.x - box1.w or box1.x >= box2.x + box2.w then
					box.dx := 0 - box.dx;
					box.x := box.x + box.dx;
					box.e := true;
				end if;
				if box1.y <= box2.y - box1.h or box1.y >= box2.y + box2.h then
					box.dy := 0 - box.dy;
					box.y := box.y + box.dy;
					box.e := true;
				end if;
			end if;
			return box;
		end function;

		procedure set_color(
			c : t_color) is
		begin
			RED <= c.r;
			GREEN <= c.g;
			BLUE <= c.b;
		end procedure;

		procedure draw_rectangle(
			r : t_rectangle;
			c : t_colors) is
			variable xx : natural;
			variable yy : natural;
		begin
			-- Move to viewport
			xx := r.x + LEFT_BORDER;
			yy := r.y + UP_BORDER;

			if x >= xx and x < xx + r.w and y >= yy and y < yy + r.h then
				if y mod 2 = 0 then
					if x mod 2 = 0 then
						set_color(c.color1);
					else
						set_color(c.color2);
					end if;
				else
					if x mod 2 = 1 then
						set_color(c.color1);
					else
						set_color(c.color2);
					end if;
				end if;
			end if;
		end procedure;

		procedure draw_circle(
			r : t_rectangle;
			cR : std_logic;
			cG : std_logic;
			cB : std_logic) is
			variable xx : natural;
			variable yy : natural;
			variable rr : natural;
		begin
			-- Move to viewport
			rr := r.w / 2;
			xx := r.x + LEFT_BORDER + rr;
			yy := r.y + UP_BORDER + rr;

			if (x-xx)*(x-xx) + (y-yy)*(y-yy) <= rr*rr then
				RED <= cR;
				GREEN <= cG;
				BLUE <= cB;
			end if;
		end procedure;
	
		procedure draw_score(
			c : t_colors;
			xx : integer;
			yy : integer;
			s : integer ) is			
		begin
			-- draw score
			draw_rectangle((
				x => xx,
				y => yy,
				dx => 0,
				dy => 0,
				w => 26,
				h => 48,
				e => false
			),
			color_white);
			if s = 0 then
				draw_rectangle((
					x => xx+6,
					y => yy+6,
					dx => 0,
					dy => 0,
					w => 14,
					h => 36,
					e => false
				),
				color_black);
			elsif s = 1 then
				draw_rectangle((
					x => xx,
					y => yy+6,
					dx => 0,
					dy => 0,
					w => 10,
					h => 36,
					e => false
				),
				color_black);
				draw_rectangle((
					x => xx+16,
					y => yy,
					dx => 0,
					dy => 0,
					w => 10,
					h => 42,
					e => false
				),
				color_black);
			elsif s = 2 then
				draw_rectangle((
					x => xx,
					y => yy+10,
					dx => 0,
					dy => 0,
					w => 20,
					h => 10,
					e => false
				),
				color_black);
				draw_rectangle((
					x => xx+6,
					y => yy+28,
					dx => 0,
					dy => 0,
					w => 20,
					h => 10,
					e => false
				),
				color_black);
			elsif s = 3 then
				draw_rectangle((
					x => xx,
					y => yy+6,
					dx => 0,
					dy => 0,
					w => 20,
					h => 15,
					e => false
				),
				color_black);
				draw_rectangle((
					x => xx,
					y => yy+27,
					dx => 0,
					dy => 0,
					w => 20,
					h => 15,
					e => false
				),
				color_black);
			elsif s = 4 then
				draw_rectangle((
					x => xx+6,
					y => yy,
					dx => 0,
					dy => 0,
					w => 14,
					h => 21,
					e => false
				),
				color_black);
				draw_rectangle((
					x => xx,
					y => yy+27,
					dx => 0,
					dy => 0,
					w => 20,
					h => 21,
					e => false
				),
				color_black);
			elsif s = 5 then
				draw_rectangle((
					x => xx+6,
					y => yy+10,
					dx => 0,
					dy => 0,
					w => 20,
					h => 10,
					e => false
				),
				color_black);
				draw_rectangle((
					x => xx,
					y => yy+28,
					dx => 0,
					dy => 0,
					w => 20,
					h => 10,
					e => false
				),
				color_black);
			elsif s = 6 then
				draw_rectangle((
					x => xx+6,
					y => yy+6,
					dx => 0,
					dy => 0,
					w => 20,
					h => 15,
					e => false
				),
				color_black);
				draw_rectangle((
					x => xx+6,
					y => yy+27,
					dx => 0,
					dy => 0,
					w => 14,
					h => 15,
					e => false
				),
				color_black);
			elsif s = 7 then
				draw_rectangle((
					x => xx,
					y => yy+6,
					dx => 0,
					dy => 0,
					w => 20,
					h => 42,
					e => false
				),
				color_black);
			elsif s = 8 then
				draw_rectangle((
					x => xx+6,
					y => yy+6,
					dx => 0,
					dy => 0,
					w => 14,
					h => 15,
					e => false
				),
				color_black);
				draw_rectangle((
					x => xx+6,
					y => yy+27,
					dx => 0,
					dy => 0,
					w => 14,
					h => 15,
					e => false
				),
				color_black);
			elsif s = 9 then
				draw_rectangle((
					x => xx+6,
					y => yy+6,
					dx => 0,
					dy => 0,
					w => 14,
					h => 15,
					e => false
				),
				color_black);
				draw_rectangle((
					x => xx,
					y => yy+27,
					dx => 0,
					dy => 0,
					w => 20,
					h => 15,
					e => false
				),
				color_black);
				
			-- if  then
			-- elsif s = 2 then
			end if;

		end procedure;

		procedure draw_net(
		c : t_colors) is
		begin
			draw_rectangle((
				x => (GAME_WIDTH/2)-25,
				y => (GAME_HEIGHT/2)-3,
				dx => 0,
				dy => 0,
				w => 50,
				h => 6,
				e => false
				),
				color_white);
			draw_rectangle((
				x => (GAME_WIDTH/2)+75,
				y => (GAME_HEIGHT/2)-3,
				dx => 0,
				dy => 0,
				w => 50,
				h => 6,
				e => false
				),
				color_white);
			draw_rectangle((
				x => (GAME_WIDTH/2)-125,
				y => (GAME_HEIGHT/2)-3,
				dx => 0,
				dy => 0,
				w => 50,
				h => 6,
				e => false
				),
				color_white);
			draw_rectangle((
				x => (GAME_WIDTH/2)-225,
				y => (GAME_HEIGHT/2)-3,
				dx => 0,
				dy => 0,
				w => 50,
				h => 6,
				e => false
				),
				color_white);
			draw_rectangle((
				x => (GAME_WIDTH/2)+175,
				y => (GAME_HEIGHT/2)-3,
				dx => 0,
				dy => 0,
				w => 50,
				h => 6,
				e => false
				),
				color_white);
		end procedure;

		procedure draw_start(
		c : t_colors) is
		begin
			
			--draw P
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85),
				y => ((GAME_HEIGHT/2)-20),
				dx => 0,
				dy => 0,
				w => 30,
				h => 40,
				e => false
				),
				color_red);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+10,
				y => ((GAME_HEIGHT/2)-20)+10,
				dx => 0,
				dy => 0,
				w => 10,
				h => 10,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+10,
				y => ((GAME_HEIGHT/2)-20)+30,
				dx => 0,
				dy => 0,
				w => 20,
				h => 10,
				e => false
				),
				color_black);

			--draw R
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+35,
				y => ((GAME_HEIGHT/2)-20),
				dx => 0,
				dy => 0,
				w => 30,
				h => 40,
				e => false
				),
				color_red);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+10+35,
				y => ((GAME_HEIGHT/2)-20)+10,
				dx => 0,
				dy => 0,
				w => 10,
				h => 10,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+10+35,
				y => ((GAME_HEIGHT/2)-20)+30,
				dx => 0,
				dy => 0,
				w => 10,
				h => 10,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+20+35,
				y => ((GAME_HEIGHT/2)-20)+25,
				dx => 0,
				dy => 0,
				w => 10,
				h => 5,
				e => false
				),
				color_black);

			--draw E
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+70,
				y => ((GAME_HEIGHT/2)-20),
				dx => 0,
				dy => 0,
				w => 30,
				h => 40,
				e => false
				),
				color_red);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+10+70,
				y => ((GAME_HEIGHT/2)-20)+10,
				dx => 0,
				dy => 0,
				w => 20,
				h => 5,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+25+70,
				y => ((GAME_HEIGHT/2)-20)+15,
				dx => 0,
				dy => 0,
				w => 10,
				h => 10,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+10+70,
				y => ((GAME_HEIGHT/2)-20)+25,
				dx => 0,
				dy => 0,
				w => 20,
				h => 5,
				e => false
				),
				color_black);
			--draw S S
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+105,
				y => ((GAME_HEIGHT/2)-20),
				dx => 0,
				dy => 0,
				w => 30,
				h => 40,
				e => false
				),
				color_red);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+10+105,
				y => ((GAME_HEIGHT/2)-20)+10,
				dx => 0,
				dy => 0,
				w => 10,
				h => 5,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+20+105,
				y => ((GAME_HEIGHT/2)-20)+12,
				dx => 0,
				dy => 0,
				w => 10,
				h => 3,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+105,
				y => ((GAME_HEIGHT/2)-20)+25,
				dx => 0,
				dy => 0,
				w => 10,
				h => 3,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+10+105,
				y => ((GAME_HEIGHT/2)-20)+25,
				dx => 0,
				dy => 0,
				w => 10,
				h => 5,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+140,
				y => ((GAME_HEIGHT/2)-20),
				dx => 0,
				dy => 0,
				w => 30,
				h => 40,
				e => false
				),
				color_red);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+10+140,
				y => ((GAME_HEIGHT/2)-20)+10,
				dx => 0,
				dy => 0,
				w => 10,
				h => 5,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+20+140,
				y => ((GAME_HEIGHT/2)-20)+12,
				dx => 0,
				dy => 0,
				w => 10,
				h => 3,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+140,
				y => ((GAME_HEIGHT/2)-20)+25,
				dx => 0,
				dy => 0,
				w => 10,
				h => 3,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-85)+10+140,
				y => ((GAME_HEIGHT/2)-20)+25,
				dx => 0,
				dy => 0,
				w => 10,
				h => 5,
				e => false
				),
				color_black);
			--draw yellow bt
			draw_circle((
				x => ((GAME_WIDTH/2)-20),
				y => ((GAME_HEIGHT/2)+30),
				dx => 0,
				dy => 0,
				w => 40,
				h => 40,
				e => false
				), '1', '1', '0');
			
		end procedure;

		procedure draw_win(
		c : t_colors;
		p : integer ) is
		begin
			
			if p = 1 then
				draw_rectangle((
				x => ((GAME_WIDTH/2)-50),
				y => ((GAME_HEIGHT/2)-50),
				dx => 0,
				dy => 0,
				w => 100,
				h => 100,
				e => false
				),
				color_blue);
			elsif p = 2 then
				draw_rectangle((
				x => ((GAME_WIDTH/2)-50),
				y => ((GAME_HEIGHT/2)-50),
				dx => 0,
				dy => 0,
				w => 100,
				h => 100,
				e => false
				),
				color_green);
			end if;
			--draw w
			draw_rectangle((
				x => ((GAME_WIDTH/2)-50+13),
				y => ((GAME_HEIGHT/2)-50+30),
				dx => 0,
				dy => 0,
				w => 5,
				h => 35,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-50+18),
				y => ((GAME_HEIGHT/2)-50+65),
				dx => 0,
				dy => 0,
				w => 5,
				h => 5,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-50+23),
				y => ((GAME_HEIGHT/2)-50+35),
				dx => 0,
				dy => 0,
				w => 5,
				h => 30,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-50+28),
				y => ((GAME_HEIGHT/2)-50+65),
				dx => 0,
				dy => 0,
				w => 5,
				h => 5,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)-50+33),
				y => ((GAME_HEIGHT/2)-50+30),
				dx => 0,
				dy => 0,
				w => 5,
				h => 35,
				e => false
				),
				color_black);
			-- draw i
			draw_rectangle((
				x => ((GAME_WIDTH/2)),
				y => ((GAME_HEIGHT/2)-50+30),
				dx => 0,
				dy => 0,
				w => 5,
				h => 40,
				e => false
				),
				color_black);
			--draw n
			draw_rectangle((
				x => ((GAME_WIDTH/2)+17),
				y => ((GAME_HEIGHT/2)-50+30),
				dx => 0,
				dy => 0,
				w => 5,
				h => 40,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)+22),
				y => ((GAME_HEIGHT/2)-50+30),
				dx => 0,
				dy => 0,
				w => 10,
				h => 5,
				e => false
				),
				color_black);
			draw_rectangle((
				x => ((GAME_WIDTH/2)+32),
				y => ((GAME_HEIGHT/2)-50+30+5),
				dx => 0,
				dy => 0,
				w => 5,
				h => 35,
				e => false
				),
				color_black);
			

			
			
		end procedure;


		variable game_counter : natural range 0 to 1000000 := 0;
		variable gcounter : natural := 0;
		variable score_PY1 : integer := 0;
		variable score_PY2 : integer := 0;
		variable pywin : integer := 0;
        variable state : integer := 0;
		variable ready : boolean := false;
		variable playing : boolean := false;
		variable maxscore : boolean := false;
		variable gamestop : boolean := true;


		variable player1 : t_rectangle := (
			x => (GAME_WIDTH / 2 )-24,
			y => 50,
			dx => 0,
			dy => 0,
			w => 48,
			h => 8,
			e => false
		);
		variable player2 : t_rectangle := (
			x => (GAME_WIDTH / 2)-24,
			y => GAME_HEIGHT - 50 - 8,
			dx => 0,
			dy => 0,
			w => 48,
			h => 8,
			e => false
		);

		variable ball : t_rectangle := (
			x => GAME_WIDTH / 2,
			y => GAME_HEIGHT / 2,
			dx => 1,
			dy => 1,
			w => 8,
			h => 8,
			e => false
		);

	
	begin

		if CLOCK'event and CLOCK = '1' then
			
			if ready = false and playing = false and maxscore = false then
                state := 1;
				if to_integer(P1_READY) = 0 and to_integer(P2_READY) = 0 then
					ready := true;
					playing := true;
                    state := 2;
				end if;
			end if;
			if ready and playing then
				if gamestop = true then
					if to_integer(P1_READY) = 0  then
						gamestop := false;
					end if;
				elsif gamestop = false then
					if to_integer(P2_READY) = 0 then
						gamestop := true;
					end if;
				end if;
			end if;

			
            game_counter := game_counter + 1;
            if game_counter = 100000 then
                game_counter := 0;
                gcounter := gcounter + 1;
				if playing and maxscore = false then
					-- Players Movement
	
					player1.dx := to_integer(P1_LEFT) - to_integer(P1_RIGHT);
					player2.dx := to_integer(P2_LEFT) - to_integer(P2_RIGHT);
				end if;
				-- Player1 Movement Applied
				player1.x := player1.x + player1.dx;
				player1.x := clamp(player1.x, 0, GAME_WIDTH - player1.w);
	
	
				-- Player2 Movement Applied
				player2.x := player2.x + player2.dx;
				player2.x := clamp(player2.x, 0, GAME_WIDTH - player2.w);
                    if gcounter > 800 then
                        
						

                        -- Ball Bounce to Screen
                        if ball.x = 1 or ball.x = GAME_WIDTH - ball.w then
                            ball.dx := 0 - ball.dx;
                        end if;
                        if ball.y = 1 or ball.y = GAME_HEIGHT - ball.h  then
                            if ball.y = 1 and maxscore = false then
                                -- add score
                                score_PY2 := score_PY2 +1;
                                if score_PY2 = 10 then
                                    maxscore := true;
                                    state := 3;
                                end if ;
                            elsif ball.y = GAME_HEIGHT - ball.h and maxscore = false then
                                -- add score
                                score_PY1 := score_PY1 +1;
                                if score_PY1 = 10 then
                                    maxscore := true;
                                    state := 3;
                                end if ;
                            end if ;
                            ball.y := GAME_HEIGHT / 2;
                            ball.x := GAME_WIDTH /2;
                            
                            
                        end if;

                        -- Ball Bounce to Player
                        ball.e := false;
                        ball := bounce(ball, player1);
                        if ball.e = false then
                            ball := bounce(ball, player2);
                        end if;

                        

                        -- Ball Movement Applied
                        if playing and gamestop = false then
                            
                            ball.x := ball.x + ball.dx;
                            ball.y := ball.y + ball.dy;
                        
                        end if;
                        ball.x := clamp(ball.x, 0, GAME_WIDTH - ball.w);
                        ball.y := clamp(ball.y, 0, GAME_HEIGHT - ball.h);
                    end if;	
				end if;

				-- Set Blackscreen
				RED <= '0';
				GREEN <= '0';
				BLUE <= '0';

				-- Draw start
				if state = 1 then
					draw_start(color_red);
                    ready := false;
                    playing := false;
                    maxscore := false;
                    gcounter := 0;
                    player1.x := (GAME_WIDTH / 2)-24;
                    player2.x := (GAME_WIDTH / 2)-24;
                    score_PY1 := 0;
                    score_PY2 := 0;
				-- draw game play
				elsif state = 2 then
					
					-- Draw Score
					draw_score(color_white, (GAME_WIDTH/2)-13, (GAME_HEIGHT/2)-96, score_PY1 ); --player1
					draw_score(color_white, (GAME_WIDTH/2)-13, (GAME_HEIGHT/2)+48, score_PY2 ); --player2

					-- Draw net
					draw_net(color_white);

					-- Draw Ball
					draw_circle(ball, '1', '0', '0');

					-- Draw Player
					draw_rectangle(player1, color_blue);
					draw_rectangle(player2, color_green);
				end if;

				-- some player win will re-game
				if state = 3 then
					playing := false;
					if score_PY1 = 10 then
						
						pywin := 1;
						
					elsif score_PY2 = 10 then
						
						pywin := 2;
						
					end if;
					draw_win(color_white,pywin);
                    if to_integer(P1_READY) = 0 and to_integer(P2_READY) = 0 then
						state := 1;
						
					end if;
				end if;
				


				-- Hsync and Vsync
				if x > 0 and x <= X_SYNC_PULSE then
					HSYNC <= '0';
				else
					HSYNC <= '1';
				end if;

				if y > 0 and y <= Y_SYNC_PULSE then
					VSYNC <= '0';
				else
					VSYNC <= '1';
				end if;

				x <= x + 1;
				if x = X_WHOLE_LINE then
					y <= y + 1;
					x <= 0;
				end if;

				if y = Y_WHOLE_FRAME then
					y <= 0;
				end if;
			end if;
		
	end process;

end Behavioral;
