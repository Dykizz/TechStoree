type PasswordVisibilityIconProps = {
  visible: boolean;
};

export default function PasswordVisibilityIcon({ visible }: PasswordVisibilityIconProps) {
  return (
    <svg aria-hidden="true" width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
      <path d="M2.3 12s3.5-5.5 9.7-5.5 9.7 5.5 9.7 5.5-3.5 5.5-9.7 5.5S2.3 12 2.3 12Z" />
      <circle cx="12" cy="12" r="2.6" />
      {!visible && <path d="M3 21 21 3" strokeWidth="2" />}
    </svg>
  );
}
