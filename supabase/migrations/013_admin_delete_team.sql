-- Admin function to permanently delete a team and its players
CREATE OR REPLACE FUNCTION events_register.admin_delete_team(
  p_team_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_player1_id UUID;
  v_player2_id UUID;
BEGIN
  IF NOT events_register.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin role required';
  END IF;

  -- Get player IDs before deleting the team
  SELECT player1_id, player2_id INTO v_player1_id, v_player2_id
  FROM events_register.teams
  WHERE id = p_team_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Team not found: %', p_team_id;
  END IF;

  -- Delete the team first (removes FK references)
  DELETE FROM events_register.teams WHERE id = p_team_id;

  -- Delete orphaned players (only if not referenced by other teams)
  DELETE FROM events_register.players p
  WHERE p.id IN (v_player1_id, v_player2_id)
    AND NOT EXISTS (
      SELECT 1 FROM events_register.teams t
      WHERE t.player1_id = p.id OR t.player2_id = p.id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
