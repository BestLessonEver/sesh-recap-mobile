-- Row Level Security (RLS) Policies
-- Enable RLS on all tables

ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE professionals ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendants ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE recaps ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Helper function to get current user's organization
CREATE OR REPLACE FUNCTION get_user_organization_id()
RETURNS UUID AS $$
  SELECT organization_id FROM professionals WHERE id = auth.uid();
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Helper function to check if user is org admin/owner
CREATE OR REPLACE FUNCTION is_org_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM professionals
    WHERE id = auth.uid()
    AND role IN ('owner', 'admin')
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- Organizations policies
CREATE POLICY "Users can view their organization"
  ON organizations FOR SELECT
  USING (id = get_user_organization_id());

CREATE POLICY "Admins can update their organization"
  ON organizations FOR UPDATE
  USING (id = get_user_organization_id() AND is_org_admin());

CREATE POLICY "Users can create organization during onboarding"
  ON organizations FOR INSERT
  WITH CHECK (true);

-- Professionals policies
CREATE POLICY "Users can view themselves"
  ON professionals FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "Users can view org members"
  ON professionals FOR SELECT
  USING (organization_id = get_user_organization_id());

CREATE POLICY "Users can update their own profile"
  ON professionals FOR UPDATE
  USING (id = auth.uid());

CREATE POLICY "Admins can update org members"
  ON professionals FOR UPDATE
  USING (organization_id = get_user_organization_id() AND is_org_admin());

CREATE POLICY "New users can create their profile"
  ON professionals FOR INSERT
  WITH CHECK (id = auth.uid());

CREATE POLICY "Admins can delete org members"
  ON professionals FOR DELETE
  USING (organization_id = get_user_organization_id() AND is_org_admin() AND id != auth.uid());

-- Attendants policies
CREATE POLICY "Users can view their attendants"
  ON attendants FOR SELECT
  USING (professional_id = auth.uid() OR organization_id = get_user_organization_id());

CREATE POLICY "Users can create attendants"
  ON attendants FOR INSERT
  WITH CHECK (professional_id = auth.uid());

CREATE POLICY "Users can update their attendants"
  ON attendants FOR UPDATE
  USING (professional_id = auth.uid());

CREATE POLICY "Users can delete their attendants"
  ON attendants FOR DELETE
  USING (professional_id = auth.uid());

-- Sessions policies
CREATE POLICY "Users can view their sessions"
  ON sessions FOR SELECT
  USING (professional_id = auth.uid() OR organization_id = get_user_organization_id());

CREATE POLICY "Users can create sessions"
  ON sessions FOR INSERT
  WITH CHECK (professional_id = auth.uid());

CREATE POLICY "Users can update their sessions"
  ON sessions FOR UPDATE
  USING (professional_id = auth.uid());

CREATE POLICY "Users can delete their sessions"
  ON sessions FOR DELETE
  USING (professional_id = auth.uid());

-- Recaps policies
CREATE POLICY "Users can view recaps for their sessions"
  ON recaps FOR SELECT
  USING (
    session_id IN (
      SELECT id FROM sessions WHERE professional_id = auth.uid()
    )
    OR organization_id = get_user_organization_id()
  );

CREATE POLICY "Users can create recaps for their sessions"
  ON recaps FOR INSERT
  WITH CHECK (
    session_id IN (
      SELECT id FROM sessions WHERE professional_id = auth.uid()
    )
  );

CREATE POLICY "Users can update recaps for their sessions"
  ON recaps FOR UPDATE
  USING (
    session_id IN (
      SELECT id FROM sessions WHERE professional_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete recaps for their sessions"
  ON recaps FOR DELETE
  USING (
    session_id IN (
      SELECT id FROM sessions WHERE professional_id = auth.uid()
    )
  );

-- Subscriptions policies
CREATE POLICY "Users can view their org subscription"
  ON subscriptions FOR SELECT
  USING (organization_id = get_user_organization_id());

CREATE POLICY "Service role can manage subscriptions"
  ON subscriptions FOR ALL
  USING (auth.role() = 'service_role');

-- Invitations policies
CREATE POLICY "Admins can view org invitations"
  ON invitations FOR SELECT
  USING (organization_id = get_user_organization_id() AND is_org_admin());

CREATE POLICY "Admins can create invitations"
  ON invitations FOR INSERT
  WITH CHECK (organization_id = get_user_organization_id() AND is_org_admin());

CREATE POLICY "Admins can delete invitations"
  ON invitations FOR DELETE
  USING (organization_id = get_user_organization_id() AND is_org_admin());

CREATE POLICY "Anyone can view invitation by token"
  ON invitations FOR SELECT
  USING (true);

-- Device tokens policies
CREATE POLICY "Users can view their device tokens"
  ON device_tokens FOR SELECT
  USING (professional_id = auth.uid());

CREATE POLICY "Users can create their device tokens"
  ON device_tokens FOR INSERT
  WITH CHECK (professional_id = auth.uid());

CREATE POLICY "Users can delete their device tokens"
  ON device_tokens FOR DELETE
  USING (professional_id = auth.uid());

-- Storage policies (for audio files bucket)
-- Note: These are created via Supabase dashboard or storage policy SQL
