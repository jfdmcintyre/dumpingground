$wsl_user = get-item 'hkcu:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss'

$def_distro_guid = $wsl_user.GetValue('DefaultDistribution')
$def_vers        = $wsl_user.GetValue('DefaultVersion')

"Default version: $def_vers"

foreach ($distro_guid in $wsl_user.GetSubKeyNames()) {

   ''

   $distro = $wsl_user.OpenSubKey($distro_guid)

   $distro.GetValue('DistributionName')   

   if ($distro_guid -eq $def_distro_guid) {
     "  This is the default distribution"
   }

   "  Version:        $($distro.GetValue('Version'          ))"
   "  Base Path:      $($distro.GetValue('BasePath'         ))"
   "  Package Family: $($distro.GetValue('PackageFamilyName'))"
   "  State:          $($distro.GetValue('State'            ))"
   "  Default UID:    $($distro.GetValue('DefaultUid'       ))"
   "  Flags:          $($distro.GetValue('Flags'            ))"

   $def_env = $distro.GetValue('DefaultEnvironment')
   "  Default Environment:"
   foreach ($env in $def_env.Split()) {
   '    {0,-10} = {1}' -f ($env.Split('='))
   }

   $distro.Close()
}