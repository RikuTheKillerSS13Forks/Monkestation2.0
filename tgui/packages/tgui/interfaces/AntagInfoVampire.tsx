import { useLocalState } from '../backend';
import {
  Section,
  Stack,
  Tabs,
} from '../components';
import { Window } from '../layouts';

export const AntagInfoVampire = (props: any) => {
  const [tab, setTab] = useLocalState('tab', 1);
  return (
    <Window width={620} height={580} theme="spookyconsole">
      <Window.Content>
        <Tabs>
          <Tabs.Tab
            icon="list"
            lineHeight="23px"
            selected={tab === 1}
            onClick={() => setTab(1)}
          >
            Introduction
          </Tabs.Tab>
          <Tabs.Tab
            icon="list"
            lineHeight="23px"
            selected={tab === 2}
            onClick={() => setTab(2)}
          >
            Clan & Powers
          </Tabs.Tab>
        </Tabs>
        {tab === 1 && <VampireIntro />}
        {/*
        {tab === 2 && <VampireClan />}
        */}
      </Window.Content>
    </Window>
  );
};

const VampireIntro = () => {
  return (
    <Stack vertical fill>
      <Stack.Item minHeight="16rem">
        <Section scrollable fill>
          <Stack vertical>
            <Stack.Item textColor="red" fontSize="20px">
              You are a vampire, an undead blood-seeking monster living
              aboard the station.
            </Stack.Item>
            {/*
            <Stack.Item>
              <ObjectivePrintout />
            </Stack.Item>
            */}
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section fill title="Strengths and Weaknesses">
          <Stack vertical>
            <Stack.Item>
              <span>
                You slowly recover from injuries and depend on the lifeforce
                of living sapients to sustain yourself. Don&apos;t abstain from
                indulging in blood for too long, or else you&apos;ll
              </span>
              <span className={'color-red'}> turn to dust!</span><br />
              <br />
              <span>
                Avoid being detected by the masses, or else the crew
                may obtain countermeasures such as garlic or silver.
                You can strategically convert others to your cause
                to sew disarray into the upper ranks. Just make sure
                to keep your thralls in check until they mature.
              </span>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section fill title="Items">
          <Stack vertical>
            <Stack.Item>
              You can rest in a <b>Coffin</b> to recover from more gruesome injuries.
              <br />
              If you lack adequate protection, <b>starlight</b> will burn you to death.
              <br />
              Your appearance and lack of blood or genes are your defining traits.
              Masquerade can be used to disguise yourself as a mortal.
              <br />
            </Stack.Item>
            <Stack.Item>
              <Section textAlign="center" textColor="red" fontSize="20px">
                Other vampires are not necessarily your allies, but your
                survival may depend on cooperation. Betray them at your own
                discretion and peril, for it holds no inherent benefits.
              </Section>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
};
