import { motion } from 'motion/react'
import { ArrowUpRight, Box, Globe, Layers, Users } from 'lucide-react'
import { Badge } from '../../../components/ui'
import { useTranslation } from '../../../hooks/useTranslation'
import type { ActivityEntry, AdminCategory, AdminSettings, AdminStats } from '../../../types/admin'
import { ActivityList } from './ActivityList'

interface OverviewViewProps {
  counts: { scenes: number; players: number }
  stats: AdminStats
  settings: AdminSettings
  activity: ActivityEntry[]
  onSelect: (category: AdminCategory) => void
}

export function OverviewView({ counts, stats, settings, activity, onSelect }: OverviewViewProps) {
  const { t } = useTranslation()
  const cards = [
    { id: 'scenes' as const, label: t('admin_nav_scenes'), value: counts.scenes, sub: t('overview_scenes_sub', { max: settings.scenes }), icon: Layers },
    { id: 'scenes' as const, label: t('overview_public'), value: stats.public, sub: t('overview_public_sub', { distance: settings.streamDistance }), icon: Globe },
    { id: 'scenes' as const, label: t('overview_props'), value: stats.props, sub: t('overview_props_sub', { n: stats.catalog }), icon: Box },
    { id: 'players' as const, label: t('admin_nav_players'), value: counts.players, sub: t('overview_players_sub'), icon: Users },
  ]

  const rules: { key: string; enabled: boolean }[] = [
    { key: 'overview_rule_create', enabled: settings.everyoneCanCreate },
    { key: 'overview_rule_public', enabled: settings.publicEnabled },
    { key: 'overview_rule_players_publish', enabled: settings.publicEnabled && settings.playersCanPublish },
    { key: 'overview_rule_sharing', enabled: settings.sharing },
    { key: 'overview_rule_custom', enabled: settings.customModels },
    { key: 'overview_rule_groups', enabled: settings.groups },
    { key: 'overview_rule_territories', enabled: settings.territories },
  ]

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {cards.map((card, idx) => {
          const Icon = card.icon
          return (
            <motion.div
              key={card.label}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: idx * 0.05 }}
              onClick={() => onSelect(card.id)}
              className="group cursor-pointer rounded-xl border border-zinc-800/80 bg-zinc-900/60 p-4 transition hover:border-zinc-700 hover:bg-zinc-900"
            >
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-zinc-400">{card.label}</span>
                <div className="flex h-8 w-8 items-center justify-center rounded-lg border border-zinc-800 bg-zinc-950 text-zinc-300"><Icon className="h-4 w-4" /></div>
              </div>
              <div className="mt-3 flex items-baseline justify-between">
                <span className="text-2xl font-bold text-zinc-100">{card.value}</span>
                <ArrowUpRight className="h-4 w-4 text-zinc-500 transition group-hover:text-zinc-300" />
              </div>
              <p className="mt-1 text-xs text-zinc-400">{card.sub}</p>
            </motion.div>
          )
        })}
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <div className="rounded-xl border border-zinc-800/80 bg-zinc-900/40 p-5 lg:col-span-2">
          <div className="flex items-center justify-between border-b border-zinc-800/60 pb-4">
            <h3 className="text-sm font-semibold text-zinc-200">{t('overview_recent_activity')}</h3>
            <button type="button" onClick={() => onSelect('activity')} className="text-xs text-zinc-400 transition hover:text-zinc-200">{t('overview_see_all')} →</button>
          </div>
          <div className="mt-4">
            <ActivityList entries={activity.slice(0, 8)} compact />
          </div>
        </div>

        <div className="rounded-xl border border-zinc-800/80 bg-zinc-900/40 p-5">
          <h3 className="border-b border-zinc-800/60 pb-4 text-sm font-semibold text-zinc-200">{t('overview_rules')}</h3>
          <div className="mt-4 space-y-2.5">
            {rules.map((rule) => (
              <div key={rule.key} className="flex items-center justify-between gap-3 text-xs">
                <span className="text-zinc-400">{t(rule.key)}</span>
                <Badge tone={rule.enabled ? 'success' : 'neutral'}>{rule.enabled ? t('overview_on') : t('overview_off')}</Badge>
              </div>
            ))}
            <div className="space-y-1.5 border-t border-zinc-800/60 pt-3 text-xs text-zinc-400">
              <p>{t('overview_limit_scenes', { n: settings.scenes })}</p>
              <p>{t('overview_limit_props', { n: settings.props })}</p>
              <p>{t('overview_limit_radius', { n: settings.radius })}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
